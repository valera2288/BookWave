import re

from rest_framework import serializers

from apps.catalog.serializers import BookListSerializer

from .models import Order, OrderItem

CARD_NUMBER_RE = re.compile(r"^\d{12,19}$")


class CheckoutSerializer(serializers.Serializer):
    card_number = serializers.CharField(max_length=32)
    promo_code = serializers.CharField(max_length=50, required=False, allow_blank=True)

    def validate_card_number(self, value):
        digits_only = value.replace(" ", "")
        if not CARD_NUMBER_RE.match(digits_only):
            raise serializers.ValidationError("Неверный номер карты.")
        return digits_only


class OrderListSerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Order
        fields = ["id", "status", "total_amount", "item_count", "created_at"]


class OrderItemSerializer(serializers.ModelSerializer):
    book = BookListSerializer(read_only=True)

    class Meta:
        model = OrderItem
        fields = ["id", "book", "price_at_purchase"]


class OrderDetailSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ["id", "status", "total_amount", "created_at", "items"]


class OrderAdminListSerializer(serializers.ModelSerializer):
    """Список заказов в админ-панели (ТЗ): номер, покупатель, сумма, статус, дата."""

    buyer_email = serializers.EmailField(source="user.email", read_only=True)
    buyer_name = serializers.CharField(source="user.name", read_only=True)
    item_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "buyer_email",
            "buyer_name",
            "status",
            "total_amount",
            "item_count",
            "created_at",
        ]


class OrderAdminDetailSerializer(serializers.ModelSerializer):
    """Детальный просмотр заказа администратором: покупатель + состав (ТЗ)."""

    buyer_email = serializers.EmailField(source="user.email", read_only=True)
    buyer_name = serializers.CharField(source="user.name", read_only=True)
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ["id", "buyer_email", "buyer_name", "status", "total_amount", "created_at", "items"]


class OrderStatusUpdateSerializer(serializers.ModelSerializer):
    """Смена статуса заказа через выпадающий список (ТЗ) — только статус,
    состав заказа постфактум не редактируется."""

    class Meta:
        model = Order
        fields = ["status"]
