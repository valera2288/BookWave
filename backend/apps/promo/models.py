from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models


class PromoCode(models.Model):
    class DiscountType(models.TextChoices):
        PERCENT = "percent", "Процент"
        FIXED = "fixed", "Фиксированная сумма"

    code = models.CharField(max_length=50, unique=True)
    discount_type = models.CharField(max_length=10, choices=DiscountType.choices)
    # Без нижней границы отрицательная скидка проходила бы в
    # `promo.services.validate_promo` как есть и увеличивала бы итоговую
    # сумму заказа вместо уменьшения (там `discount = min(discount, order_amount)`
    # защищает только от скидки больше суммы заказа, не от отрицательной).
    discount_value = models.DecimalField(
        max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    min_order_amount = models.DecimalField(
        max_digits=8, decimal_places=2, default=0, validators=[MinValueValidator(Decimal("0"))]
    )
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    max_uses = models.PositiveIntegerField(
        null=True, blank=True, validators=[MinValueValidator(1)]
    )  # null = без ограничения

    class Meta:
        db_table = "promo_codes"

    def __str__(self):
        return self.code

    def clean(self):
        if self.discount_type == self.DiscountType.PERCENT and self.discount_value and (
            self.discount_value > 100
        ):
            raise ValidationError(
                {"discount_value": "Скидка в процентах не может превышать 100."}
            )


class PromoCodeUsage(models.Model):
    promo_code = models.ForeignKey(
        PromoCode, on_delete=models.CASCADE, related_name="usages"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="promo_code_usages"
    )
    order = models.ForeignKey(
        "orders.Order", on_delete=models.CASCADE, related_name="promo_usage"
    )
    used_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "promo_code_usages"
