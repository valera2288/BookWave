from rest_framework import serializers

from apps.catalog.models import Book
from apps.catalog.serializers import BookListSerializer

from .models import Favorite


class FavoriteSerializer(serializers.ModelSerializer):
    """Сериализатор избранного: `book` — карточка книги для списка (только
    чтение), `book_id` — id книги для добавления (только запись)."""

    book = BookListSerializer(read_only=True)
    book_id = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.filter(is_active=True), source="book", write_only=True
    )

    class Meta:
        model = Favorite
        fields = ["id", "book", "book_id", "created_at"]
        read_only_fields = ["id", "created_at"]
