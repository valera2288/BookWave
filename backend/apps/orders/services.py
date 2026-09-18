import logging
from decimal import Decimal

from django.conf import settings
from django.core.mail import send_mail
from django.db import transaction

logger = logging.getLogger(__name__)

from apps.cart.models import CartItem
from apps.cart.services import get_cart
from apps.library.models import LibraryEntry
from apps.promo.models import PromoCode, PromoCodeUsage
from apps.promo.services import PromoError, validate_promo

from .models import Order, OrderItem

# Имитация оплаты по тестовому номеру карты (ТЗ: «тестовые платёжные
# данные, имитация успешного/неуспешного платежа»), как у платёжных
# песочниц (Stripe и т.п.) — этот конкретный номер всегда отклоняется,
# любой другой формально валидный номер — успешная оплата.
DECLINED_TEST_CARD = "4000000000000002"


class CheckoutError(Exception):
    status_code = 400


class PaymentDeclinedError(CheckoutError):
    status_code = 402


def send_order_receipt_email(order):
    """Письмо с чеком — сугубо побочный эффект после уже закоммиченного
    заказа (вызывается из `transaction.on_commit`). Сбой отправки (недоступен
    SMTP, проблема кодировки консоли в dev и т.п.) не должен превращать уже
    успешно оформленный и оплаченный заказ в 500-ю ошибку для клиента —
    поэтому ошибка только логируется, а не пробрасывается наружу."""
    lines = "\n".join(
        f"- {item.book.title} — {item.price_at_purchase} ₽"
        for item in order.items.select_related("book")
    )
    try:
        send_mail(
            subject=f"Чек по заказу #{order.id} — BookWave",
            message=(
                f"Здравствуйте, {order.user.name}!\n\n"
                f"Спасибо за покупку в BookWave. Состав заказа:\n{lines}\n\n"
                f"Итого: {order.total_amount} ₽"
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[order.user.email],
        )
    except Exception:
        logger.exception("Не удалось отправить чек по заказу #%s", order.id)


def checkout(user, *, card_number, promo_code=None):
    """Атомарный checkout (ТЗ + ARCHITECTURE.md, «Checkout»):

    validate promo -> имитация оплаты -> create order -> library entries
    -> promo usage -> clear cart -> commit -> email с чеком.

    Книги, уже купленные пользователем ранее, из корзины при оплате
    исключаются (иначе — повторное списание денег за то, чем он уже
    владеет). Любая ошибка откатывает всё целиком — ни заказ, ни записи
    в библиотеке, ни списание позиций из корзины не сохраняются.
    """
    with transaction.atomic():
        cart = get_cart(user)
        items = list(cart.items.all())

        owned_book_ids = set(
            LibraryEntry.objects.filter(
                user=user, book_id__in=[item.book_id for item in items]
            ).values_list("book_id", flat=True)
        )
        items = [item for item in items if item.book_id not in owned_book_ids]

        if not items:
            raise CheckoutError("Корзина пуста.")

        subtotal = sum((item.book.price for item in items), Decimal("0"))

        promo = None
        discount = Decimal("0")
        if promo_code:
            try:
                promo, discount = validate_promo(
                    promo_code, subtotal, queryset=PromoCode.objects.select_for_update()
                )
            except PromoError as e:
                raise CheckoutError(str(e)) from e

        if card_number == DECLINED_TEST_CARD:
            raise PaymentDeclinedError(
                "Оплата отклонена. Проверьте платёжные данные и повторите попытку."
            )

        total = max(subtotal - discount, Decimal("0"))

        order = Order.objects.create(user=user, status=Order.Status.PAID, total_amount=total)
        OrderItem.objects.bulk_create(
            OrderItem(order=order, book=item.book, price_at_purchase=item.book.price)
            for item in items
        )
        LibraryEntry.objects.bulk_create(
            (LibraryEntry(user=user, book=item.book) for item in items),
            ignore_conflicts=True,
        )
        if promo is not None:
            PromoCodeUsage.objects.create(promo_code=promo, user=user, order=order)

        CartItem.objects.filter(cart=cart, book_id__in=[item.book_id for item in items]).delete()

        transaction.on_commit(lambda: send_order_receipt_email(order))

    return order
