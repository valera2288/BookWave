from rest_framework import serializers

from apps.catalog.models import Book

from .models import Bookmark


class BookmarkSerializer(serializers.ModelSerializer):
    # Без фильтра is_active: мягко удалённая книга остаётся доступной для
    # чтения владельцам (ТЗ), значит и закладки в ней тоже. Доступ проверяет
    # BookmarkListCreateView.perform_create (запись в библиотеке).
    book_id = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.all(), source="book", write_only=True
    )

    class Meta:
        model = Bookmark
        fields = ["id", "book_id", "position", "created_at"]
        read_only_fields = ["id", "created_at"]
