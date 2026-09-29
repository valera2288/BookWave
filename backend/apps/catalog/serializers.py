from rest_framework import serializers

from .models import Author, Book, Genre
from .validators import validate_isbn_format


class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ["id", "name"]


class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ["id", "name"]


class BookListSerializer(serializers.ModelSerializer):
    """Карточка книги в сетке каталога: обложка, название, автор, цена, рейтинг."""

    authors = AuthorSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(read_only=True)
    rating_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Book
        fields = [
            "id",
            "title",
            "authors",
            "cover",
            "price",
            "average_rating",
            "rating_count",
        ]


class BookDetailSerializer(serializers.ModelSerializer):
    """Карточка книги: без файлов — их отдаёт только защищённый эндпоинт
    библиотеки/читалки (Phase 6), не публичный каталог."""

    authors = AuthorSerializer(many=True, read_only=True)
    genres = GenreSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(read_only=True)
    rating_count = serializers.IntegerField(read_only=True)
    available_formats = serializers.SerializerMethodField()

    class Meta:
        model = Book
        fields = [
            "id",
            "title",
            "authors",
            "genres",
            "language",
            "publisher",
            "publication_year",
            "page_count",
            "isbn",
            "price",
            "average_rating",
            "rating_count",
            "description",
            "cover",
            "available_formats",
        ]

    def get_available_formats(self, obj):
        # Сами файлы сюда не входят (см. докстринг класса) — только список
        # форматов, чтобы мобильный клиент знал, какой вьюер для фрагмента
        # открывать, не обращаясь к защищённому эндпоинту вслепую.
        formats = []
        if obj.epub_file:
            formats.append("epub")
        if obj.pdf_file:
            formats.append("pdf")
        if obj.fb2_file:
            formats.append("fb2")
        return formats


class BookAdminSerializer(serializers.ModelSerializer):
    """CRUD для админ-панели. `is_active` — только для чтения (пометка в
    списке), `deleted_at` не входит: в форме книги по ТЗ их нет, мягкое
    удаление — отдельным действием (см. BookAdminDetailView.destroy)."""

    # allow_empty=False — автор и жанр обязательны (ТЗ, форма книги); по
    # умолчанию many=True пропускает пустой список.
    authors = serializers.PrimaryKeyRelatedField(
        many=True, allow_empty=False, queryset=Author.objects.all()
    )
    genres = serializers.PrimaryKeyRelatedField(
        many=True, allow_empty=False, queryset=Genre.objects.all()
    )

    class Meta:
        model = Book
        fields = [
            "id",
            "title",
            "authors",
            "genres",
            "language",
            "publisher",
            "publication_year",
            "page_count",
            "isbn",
            "price",
            "description",
            "cover",
            "epub_file",
            "pdf_file",
            "fb2_file",
            "is_active",
        ]
        # Только для отображения в списке (пометка «удалена») — менять его
        # можно лишь мягким удалением (BookAdminDetailView.destroy).
        read_only_fields = ["is_active"]

    def validate_isbn(self, value):
        # Часть сидовых книг в базе имеет нестандартные тестовые ISBN — не
        # блокируем их редактирование, если сам ISBN не менялся (см.
        # докстринг validate_isbn_format). Для новых книг и реальных правок
        # ISBN проверка обязательна.
        if self.instance and self.instance.isbn == value:
            return value
        validate_isbn_format(value)
        return value
