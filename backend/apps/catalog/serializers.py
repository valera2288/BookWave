from rest_framework import serializers

from .models import Author, Book, Genre


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
    """CRUD для админ-панели. `is_active`/`deleted_at` сюда намеренно не
    входят — их нет в форме добавления/редактирования книги по ТЗ, мягкое
    удаление отдельным действием (см. BookAdminViewSet.destroy)."""

    authors = serializers.PrimaryKeyRelatedField(many=True, queryset=Author.objects.all())
    genres = serializers.PrimaryKeyRelatedField(many=True, queryset=Genre.objects.all())

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
        ]
