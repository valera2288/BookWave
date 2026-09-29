from django.utils import timezone
from rest_framework import serializers

from .models import PromoCode


class PromoValidateSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=50)


class PromoCodeAdminSerializer(serializers.ModelSerializer):
    """CRUD промокодов в админ-панели (ТЗ). `status` — вычисляемое поле для
    списка (активен/истёк/исчерпан), не хранится в БД."""

    usage_count = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()

    class Meta:
        model = PromoCode
        fields = [
            "id",
            "code",
            "discount_type",
            "discount_value",
            "min_order_amount",
            "valid_from",
            "valid_until",
            "max_uses",
            "usage_count",
            "status",
        ]

    def get_usage_count(self, obj):
        return obj.usages.count()

    def get_status(self, obj):
        now = timezone.now()
        if obj.valid_until < now:
            return "expired"
        if obj.max_uses is not None and self.get_usage_count(obj) >= obj.max_uses:
            return "exhausted"
        return "active"

    def validate_code(self, value):
        # Применение промокода ищет его без учёта регистра (`code__iexact`) —
        # "SALE" и "sale" одновременно дали бы 500 при проверке.
        duplicates = PromoCode.objects.filter(code__iexact=value)
        if self.instance is not None:
            duplicates = duplicates.exclude(pk=self.instance.pk)
        if duplicates.exists():
            raise serializers.ValidationError("Промокод с таким кодом уже существует.")
        return value

    def validate(self, attrs):
        # `PromoCode.clean()` уже содержит это правило, но ModelSerializer
        # не вызывает model.clean() автоматически — без дублирования здесь
        # скидка >100% прошла бы через этот новый CRUD-эндпоинт без проверки.
        discount_type = attrs.get("discount_type", getattr(self.instance, "discount_type", None))
        discount_value = attrs.get("discount_value", getattr(self.instance, "discount_value", None))
        if (
            discount_type == PromoCode.DiscountType.PERCENT
            and discount_value is not None
            and discount_value > 100
        ):
            raise serializers.ValidationError(
                {"discount_value": "Скидка в процентах не может превышать 100."}
            )

        valid_from = attrs.get("valid_from", getattr(self.instance, "valid_from", None))
        valid_until = attrs.get("valid_until", getattr(self.instance, "valid_until", None))
        if valid_from and valid_until and valid_from >= valid_until:
            raise serializers.ValidationError(
                {"valid_until": "Дата окончания должна быть позже даты начала."}
            )
        return attrs
