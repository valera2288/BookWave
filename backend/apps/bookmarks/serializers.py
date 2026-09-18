from rest_framework import serializers

from apps.catalog.models import Book

from .models import Bookmark


class BookmarkSerializer(serializers.ModelSerializer):
    book_id = serializers.PrimaryKeyRelatedField(
        queryset=Book.objects.filter(is_active=True), source="book", write_only=True
    )

    class Meta:
        model = Bookmark
        fields = ["id", "book_id", "position", "created_at"]
        read_only_fields = ["id", "created_at"]
