from datetime import timedelta
from decimal import Decimal

from django.core import mail
from django.test import RequestFactory, TestCase
from django.utils import timezone
from rest_framework.test import force_authenticate

from apps.cart.models import Cart, CartItem
from apps.catalog.models import Book
from apps.library.models import LibraryEntry
from apps.promo.models import PromoCode
from apps.users.models import User

from .models import Order, OrderItem
from .services import CheckoutError, PaymentDeclinedError, checkout
from .views import CheckoutView

VALID_CARD = "4242424242424242"
DECLINED_CARD = "4000000000000002"


def _make_user(email="buyer@test.local"):
    return User.objects.create_user(email=email, password="testpass123", name="Buyer")


def _make_book(isbn, price="100.00", is_active=True):
    return Book.objects.create(title=f"Book {isbn}", price=price, isbn=isbn, is_active=is_active)


def _add_to_cart(user, *books):
    cart, _ = Cart.objects.get_or_create(user=user)
    for book in books:
        CartItem.objects.create(cart=cart, book=book)
    return cart


class CheckoutTests(TestCase):
    def test_successful_checkout_creates_order_and_library_entries_and_clears_cart(self):
        user = _make_user()
        book1 = _make_book("1000000000001", price="100.00")
        book2 = _make_book("1000000000002", price="250.00")
        _add_to_cart(user, book1, book2)

        with self.captureOnCommitCallbacks(execute=True):
            order = checkout(user, card_number=VALID_CARD)

        self.assertEqual(order.status, Order.Status.PAID)
        self.assertEqual(order.total_amount, Decimal("350.00"))
        self.assertEqual(OrderItem.objects.filter(order=order).count(), 2)
        self.assertEqual(
            set(LibraryEntry.objects.filter(user=user).values_list("book_id", flat=True)),
            {book1.id, book2.id},
        )
        self.assertEqual(CartItem.objects.filter(cart__user=user).count(), 0)
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn(str(order.id), mail.outbox[0].subject)

    def test_declined_card_rolls_back_everything(self):
        user = _make_user()
        book = _make_book("1000000000003")
        _add_to_cart(user, book)

        with self.assertRaises(PaymentDeclinedError):
            checkout(user, card_number=DECLINED_CARD)

        self.assertEqual(Order.objects.count(), 0)
        self.assertEqual(LibraryEntry.objects.filter(user=user).count(), 0)
        self.assertEqual(CartItem.objects.filter(cart__user=user).count(), 1)
        self.assertEqual(len(mail.outbox), 0)

    def test_invalid_promo_rolls_back_everything(self):
        user = _make_user()
        book = _make_book("1000000000004")
        _add_to_cart(user, book)

        with self.assertRaises(CheckoutError):
            checkout(user, card_number=VALID_CARD, promo_code="NOPE")

        self.assertEqual(Order.objects.count(), 0)
        self.assertEqual(LibraryEntry.objects.filter(user=user).count(), 0)
        self.assertEqual(CartItem.objects.filter(cart__user=user).count(), 1)

    def test_already_owned_book_is_excluded_from_charge(self):
        user = _make_user()
        owned_book = _make_book("1000000000005", price="100.00")
        new_book = _make_book("1000000000006", price="200.00")
        LibraryEntry.objects.create(user=user, book=owned_book)
        _add_to_cart(user, owned_book, new_book)

        with self.captureOnCommitCallbacks(execute=True):
            order = checkout(user, card_number=VALID_CARD)

        self.assertEqual(order.total_amount, Decimal("200.00"))
        self.assertEqual(OrderItem.objects.filter(order=order).count(), 1)
        self.assertEqual(OrderItem.objects.get(order=order).book_id, new_book.id)
        # already-owned item stays in cart untouched, wasn't charged for
        self.assertTrue(CartItem.objects.filter(cart__user=user, book=owned_book).exists())

    def test_checkout_with_valid_promo_applies_discount_and_records_usage(self):
        user = _make_user()
        book = _make_book("1000000000007", price="1000.00")
        _add_to_cart(user, book)
        now = timezone.now()
        PromoCode.objects.create(
            code="SAVE10",
            discount_type=PromoCode.DiscountType.PERCENT,
            discount_value=Decimal("10"),
            min_order_amount=Decimal("0"),
            valid_from=now - timedelta(days=1),
            valid_until=now + timedelta(days=1),
        )

        with self.captureOnCommitCallbacks(execute=True):
            order = checkout(user, card_number=VALID_CARD, promo_code="SAVE10")

        self.assertEqual(order.total_amount, Decimal("900.00"))
        self.assertEqual(order.promo_usage.count(), 1)


class CheckoutViewResponseTests(TestCase):
    """Регрессия на баг, найденный вручную: `BookListSerializer` молча
    теряет average_rating/rating_count, если книга в ответе не аннотирована
    через `annotate_ratings` (DRF считает read_only-поле без атрибута
    необязательным и просто пропускает его, без ошибки) — а мобильный
    клиент парсит `rating_count` без `?`, то есть упал бы на таком ответе."""

    def test_checkout_response_books_include_rating_fields(self):
        user = _make_user("ratings@test.local")
        book = _make_book("1000000000008")
        _add_to_cart(user, book)

        request = RequestFactory().post(
            "/api/orders/checkout/", {"card_number": VALID_CARD}
        )
        force_authenticate(request, user=user)

        with self.captureOnCommitCallbacks(execute=True):
            response = CheckoutView.as_view()(request)

        self.assertEqual(response.status_code, 201)
        book_data = response.data["items"][0]["book"]
        self.assertIn("average_rating", book_data)
        self.assertIn("rating_count", book_data)
