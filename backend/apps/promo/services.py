from decimal import Decimal

from django.utils import timezone

from .models import PromoCode


class PromoError(Exception):
    """Промокод не проходит проверку (ТЗ: не найден / истёк срок /
    условия не выполнены)."""


def validate_promo(code, order_amount, *, queryset=None):
    """Проверяет промокод против суммы заказа и считает скидку.

    `queryset` — переопределяемый источник (например,
    `PromoCode.objects.select_for_update()` внутри checkout-транзакции,
    чтобы исключить гонку по `max_uses`); по умолчанию — обычный,
    для превью на экране корзины, где блокировка не нужна.
    """
    qs = queryset if queryset is not None else PromoCode.objects.all()
    try:
        promo = qs.get(code__iexact=code)
    except PromoCode.DoesNotExist as exc:
        raise PromoError("Промокод не найден.") from exc

    now = timezone.now()
    if now < promo.valid_from or now > promo.valid_until:
        raise PromoError("Срок действия промокода истёк.")

    if order_amount < promo.min_order_amount:
        raise PromoError(
            f"Минимальная сумма заказа для этого промокода — "
            f"{promo.min_order_amount} ₽."
        )

    if promo.max_uses is not None and promo.usages.count() >= promo.max_uses:
        raise PromoError("Промокод больше не действует.")

    if promo.discount_type == PromoCode.DiscountType.PERCENT:
        discount = (order_amount * promo.discount_value / Decimal("100")).quantize(
            Decimal("0.01")
        )
    else:
        discount = promo.discount_value

    discount = min(discount, order_amount)
    return promo, discount
