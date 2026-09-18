from django.conf import settings
from django.db import models


class Order(models.Model):
    class Status(models.TextChoices):
        PAID = "paid", "Оплачен"
        CANCELLED = "cancelled", "Отменён"
        REFUNDED = "refunded", "Возврат"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders"
    )
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PAID)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "orders"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Заказ #{self.pk}"


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    book = models.ForeignKey(
        "catalog.Book", on_delete=models.PROTECT, related_name="order_items"
    )
    price_at_purchase = models.DecimalField(max_digits=8, decimal_places=2)

    class Meta:
        db_table = "order_items"
