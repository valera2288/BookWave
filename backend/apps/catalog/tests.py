from decimal import Decimal

from django.test import TestCase

from apps.orders.models import Order, OrderItem
from apps.users.models import User

from .models import Book
from .services import get_top_sellers


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Buyer")


def _make_book(isbn, price="100.00"):
    return Book.objects.create(title=f"Book {isbn}", price=price, isbn=isbn)


def _make_order(user, status=Order.Status.PAID, *books):
    order = Order.objects.create(user=user, status=status, total_amount=Decimal("0"))
    OrderItem.objects.bulk_create(
        OrderItem(order=order, book=book, price_at_purchase=book.price) for book in books
    )
    return order


class GetTopSellersTests(TestCase):
    def test_orders_by_paid_sales_count_descending(self):
        user = _make_user("buyer1@test.local")
        popular = _make_book("2000000000001")
        rare = _make_book("2000000000002")
        _make_order(user, Order.Status.PAID, popular)
        _make_order(user, Order.Status.PAID, popular, rare)

        result = list(get_top_sellers())

        self.assertEqual(result, [popular, rare])
        self.assertEqual(result[0].sales_count, 2)
        self.assertEqual(result[1].sales_count, 1)

    def test_cancelled_and_refunded_orders_are_not_counted(self):
        user = _make_user("buyer2@test.local")
        book = _make_book("2000000000003")
        _make_order(user, Order.Status.CANCELLED, book)
        _make_order(user, Order.Status.REFUNDED, book)

        self.assertEqual(list(get_top_sellers()), [])

    def test_books_without_paid_sales_are_excluded(self):
        _make_book("2000000000004")

        self.assertEqual(list(get_top_sellers()), [])

    def test_inactive_books_are_excluded(self):
        user = _make_user("buyer3@test.local")
        book = _make_book("2000000000005")
        book.is_active = False
        book.save(update_fields=["is_active"])
        _make_order(user, Order.Status.PAID, book)

        self.assertEqual(list(get_top_sellers()), [])
