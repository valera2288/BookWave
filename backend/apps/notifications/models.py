from django.conf import settings
from django.db import models


class NotificationPreference(models.Model):
    class Category(models.TextChoices):
        NEW_RELEASES = "new_releases", "Новинки"
        ORDER_STATUS = "order_status", "Статус заказа"
        REVIEW_REPLIES = "review_replies", "Ответы на отзывы"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_preferences",
    )
    category = models.CharField(max_length=20, choices=Category.choices)
    enabled = models.BooleanField(default=True)

    class Meta:
        db_table = "notification_preferences"
        constraints = [
            models.UniqueConstraint(
                fields=["user", "category"], name="unique_user_category_preference"
            )
        ]


class DeviceToken(models.Model):
    class Platform(models.TextChoices):
        ANDROID = "android", "Android"
        IOS = "ios", "iOS"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="device_tokens"
    )
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=10, choices=Platform.choices)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "device_tokens"
