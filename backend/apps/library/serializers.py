from rest_framework import serializers

from apps.catalog.serializers import BookListSerializer

from .models import LibraryEntry


class LibraryEntrySerializer(serializers.ModelSerializer):
    """«Моя библиотека» (ТЗ): книга + прогресс чтения в процентах + какие
    форматы файла вообще есть у книги (нужно клиенту, чтобы решить, какой
    вьюер открывать, не дёргая защищённый файловый эндпоинт вслепую)."""

    book = BookListSerializer(read_only=True)
    available_formats = serializers.SerializerMethodField()

    class Meta:
        model = LibraryEntry
        fields = ["book", "available_formats", "progress", "progress_updated_at", "added_at"]

    def get_available_formats(self, obj):
        book = obj.book
        formats = []
        if book.epub_file:
            formats.append("epub")
        if book.pdf_file:
            formats.append("pdf")
        if book.fb2_file:
            formats.append("fb2")
        return formats


class ProgressUpdateSerializer(serializers.Serializer):
    progress = serializers.IntegerField(min_value=0, max_value=100)
    # клиентская метка времени сохранения — используется для last-write-wins
    # сравнения на сервере, не серверное "сейчас" (ТЗ: конфликт разрешается
    # по более поздней отметке времени сохранения на устройстве).
    progress_updated_at = serializers.DateTimeField()
