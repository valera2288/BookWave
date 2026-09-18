from decimal import Decimal

from rest_framework import serializers

from apps.catalog.models import Book
from apps.catalog.serializers import BookListSerializer

from .models import Cart, CartItem


class CartItemSerializer(serializers.ModelSerializer):
    book = BookListSerializer(read_only=True)

    class Meta:
        model = CartItem
        fields = ["id", "book", "added_at"]


class CartSerializer(serializers.ModelSerializer):
    """Корзина целиком: позиции + итоговая сумма (ТЗ: «блок расчёта: сумма
    товаров»). Скидка по промокоду — Phase 5, здесь её ещё нет."""

    items = CartItemSerializer(many=True, read_only=True)
    total = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ["items", "total"]

    def get_total(self, cart):
        return sum((item.book.price for item in cart.items.all()), Decimal("0"))


class CartItemCreateSerializer(serializers.Serializer):
    book_id = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.filter(is_active=True), source="book"
    )
