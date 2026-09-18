from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from .models import PromoCode
from .services import PromoError, validate_promo


def _make_promo(**overrides):
    now = timezone.now()
    defaults = {
        "code": "SUMMER10",
        "discount_type": PromoCode.DiscountType.PERCENT,
        "discount_value": Decimal("10"),
        "min_order_amount": Decimal("0"),
        "valid_from": now - timedelta(days=1),
        "valid_until": now + timedelta(days=1),
        "max_uses": None,
    }
    defaults.update(overrides)
    return PromoCode.objects.create(**defaults)


class ValidatePromoTests(TestCase):
    def test_percent_discount_is_calculated_from_order_amount(self):
        _make_promo(discount_type=PromoCode.DiscountType.PERCENT, discount_value=Decimal("10"))

        promo, discount = validate_promo("SUMMER10", Decimal("1000.00"))

        self.assertEqual(discount, Decimal("100.00"))
        self.assertEqual(promo.code, "SUMMER10")

    def test_fixed_discount_is_clamped_to_order_amount(self):
        _make_promo(discount_type=PromoCode.DiscountType.FIXED, discount_value=Decimal("500"))

        _, discount = validate_promo("SUMMER10", Decimal("300.00"))

        self.assertEqual(discount, Decimal("300.00"))

    def test_unknown_code_is_rejected(self):
        with self.assertRaises(PromoError):
            validate_promo("DOES-NOT-EXIST", Decimal("100"))

    def test_expired_code_is_rejected(self):
        now = timezone.now()
        _make_promo(valid_from=now - timedelta(days=10), valid_until=now - timedelta(days=1))

        with self.assertRaises(PromoError):
            validate_promo("SUMMER10", Decimal("100"))

    def test_order_below_minimum_amount_is_rejected(self):
        _make_promo(min_order_amount=Decimal("2000"))

        with self.assertRaises(PromoError):
            validate_promo("SUMMER10", Decimal("500"))

    def test_exhausted_max_uses_is_rejected(self):
        from apps.orders.models import Order
        from apps.promo.models import PromoCodeUsage
        from apps.users.models import User

        promo = _make_promo(max_uses=1)
        user = User.objects.create_user(email="u1@test.local", password="testpass123", name="U1")
        order = Order.objects.create(user=user, status=Order.Status.PAID, total_amount=Decimal("10"))
        PromoCodeUsage.objects.create(promo_code=promo, user=user, order=order)

        with self.assertRaises(PromoError):
            validate_promo("SUMMER10", Decimal("100"))
