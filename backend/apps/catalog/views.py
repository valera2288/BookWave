from decimal import Decimal, InvalidOperation

from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import NotificationPreference
from apps.notifications.services import send_push_to_category
from apps.users.permissions import IsAdminRole

from .models import Author, Book, Genre
from .pagination import AdminCatalogPagination, PublicCatalogPagination
from .serializers import (
    AuthorSerializer,
    BookAdminSerializer,
    BookDetailSerializer,
    BookListSerializer,
    GenreSerializer,
)
from .services import (
    RECOMMENDATIONS_LIMIT,
    TOP_SELLERS_LIMIT,
    annotate_ratings,
    get_recommendations,
    get_top_sellers,
)

SORT_OPTIONS = {
    "default": "-created_at",
    "cheap_first": "price",
    "expensive_first": "-price",
    "rating": "-average_rating",
    "newest": "-created_at",
}


def _to_int_list(value):
    """Парсит "1,2,3" в [1, 2, 3], молча отбрасывая нечисловой мусор —
    фильтр по жанру не должен падать 500-й из-за кривого query-параметра."""
    result = []
    for chunk in value.split(","):
        chunk = chunk.strip()
        if chunk.isdigit():
            result.append(int(chunk))
    return result


def _to_decimal(value):
    try:
        return Decimal(value)
    except (InvalidOperation, TypeError):
        return None


def _apply_public_filters(queryset, params):
    """Общие поиск/фильтры для публичного каталога (список и не только)."""
    search = params.get("search", "").strip()
    if search:
        queryset = queryset.filter(
            Q(title__icontains=search)
            | Q(authors__name__icontains=search)
            | Q(isbn__icontains=search)
        )

    genre_param = params.get("genre")
    if genre_param:
        genre_ids = _to_int_list(genre_param)
        if genre_ids:
            queryset = queryset.filter(genres__id__in=genre_ids)

    language = params.get("language")
    if language:
        queryset = queryset.filter(language__iexact=language)

    price_min = _to_decimal(params.get("price_min"))
    if price_min is not None:
        queryset = queryset.filter(price__gte=price_min)

    price_max = _to_decimal(params.get("price_max"))
    if price_max is not None:
        queryset = queryset.filter(price__lte=price_max)

    rating_min = _to_decimal(params.get("rating_min"))
    if rating_min is not None:
        queryset = queryset.filter(average_rating__gte=rating_min)

    return queryset


class BookListView(generics.ListAPIView):
    """Каталог: поиск по названию/автору/ISBN, фильтры по жанру/языку/
    цене/рейтингу, сортировка, пагинация по 20 (ТЗ)."""

    serializer_class = BookListSerializer
    pagination_class = PublicCatalogPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = annotate_ratings(
            Book.objects.filter(is_active=True).prefetch_related("authors", "genres")
        )
        queryset = _apply_public_filters(queryset, self.request.query_params)
        sort = SORT_OPTIONS.get(self.request.query_params.get("sort"), SORT_OPTIONS["default"])
        return queryset.distinct().order_by(sort)


class BookDetailView(generics.RetrieveAPIView):
    """Карточка книги. Файлы книги сюда не входят — их отдаёт только
    защищённый эндпоинт библиотеки/читалки (Phase 6)."""

    serializer_class = BookDetailSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return annotate_ratings(Book.objects.filter(is_active=True))


class GenreListView(generics.ListAPIView):
    serializer_class = GenreSerializer
    permission_classes = [AllowAny]
    pagination_class = None
    queryset = Genre.objects.all()


class AuthorListView(generics.ListAPIView):
    serializer_class = AuthorSerializer
    permission_classes = [AllowAny]
    pagination_class = None
    queryset = Author.objects.all()


class LanguageListView(APIView):
    """Языки, реально встречающиеся среди активных книг — для выпадающего
    списка на экране фильтров (а не гадать фиксированный набор заранее)."""

    permission_classes = [AllowAny]

    def get(self, request):
        languages = (
            Book.objects.filter(is_active=True)
            .exclude(language="")
            .order_by("language")
            .values_list("language", flat=True)
            .distinct()
        )
        return Response(list(languages))


class RecommendationsView(generics.ListAPIView):
    """Блок «Рекомендуем» на главной — доступен только вошедшим (главная
    страница показывается сразу после входа)."""

    serializer_class = BookListSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = annotate_ratings(get_recommendations(self.request.user))
        return queryset[:RECOMMENDATIONS_LIMIT]


class TopSellersView(generics.ListAPIView):
    """Блок «Топ продаж» на главной (ТЗ) — не персонализирован, доступен
    так же широко, как остальной публичный каталог."""

    serializer_class = BookListSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        queryset = annotate_ratings(get_top_sellers())
        return queryset[:TOP_SELLERS_LIMIT]


class BookAdminListCreateView(generics.ListCreateAPIView):
    """Список книг в админ-панели: поиск по названию/автору, фильтр по
    жанру, пагинация по 25 (ТЗ). Видны и неактивные (мягко удалённые)."""

    serializer_class = BookAdminSerializer
    permission_classes = [IsAdminRole]
    pagination_class = AdminCatalogPagination

    def get_queryset(self):
        params = self.request.query_params
        queryset = Book.objects.all().prefetch_related("authors", "genres")

        search = params.get("search", "").strip()
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(authors__name__icontains=search)
            )

        genre_param = params.get("genre")
        if genre_param:
            genre_ids = _to_int_list(genre_param)
            if genre_ids:
                queryset = queryset.filter(genres__id__in=genre_ids)

        return queryset.distinct().order_by("-created_at")

    def perform_create(self, serializer):
        book = serializer.save()
        # Блок «Новинки» на главной уже фильтрует по дате (Phase 3) — push
        # категории «новинки» (ТЗ) отправляем сразу при добавлении книги
        # администратором, а не отдельным опросом/cron.
        send_push_to_category(
            NotificationPreference.Category.NEW_RELEASES,
            "Новинка в BookWave",
            f"«{book.title}» уже доступна в каталоге.",
        )


class BookAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Редактирование книги. Удаление — мягкое: is_active=False +
    deleted_at, файл и запись в БД не трогаем (ТЗ)."""

    serializer_class = BookAdminSerializer
    permission_classes = [IsAdminRole]
    queryset = Book.objects.all()

    def destroy(self, request, *args, **kwargs):
        book = self.get_object()
        book.is_active = False
        book.deleted_at = timezone.now()
        book.save(update_fields=["is_active", "deleted_at"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class GenreAdminListCreateView(generics.ListCreateAPIView):
    serializer_class = GenreSerializer
    permission_classes = [IsAdminRole]
    pagination_class = None
    queryset = Genre.objects.all()


class GenreAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Переименование/удаление жанра. Удаление запрещено, пока жанр
    привязан хотя бы к одной книге (ТЗ)."""

    serializer_class = GenreSerializer
    permission_classes = [IsAdminRole]
    queryset = Genre.objects.all()

    def destroy(self, request, *args, **kwargs):
        genre = self.get_object()
        if genre.books.exists():
            return Response(
                {"detail": "Нельзя удалить жанр, привязанный к книгам."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return super().destroy(request, *args, **kwargs)


class AuthorAdminListCreateView(generics.ListCreateAPIView):
    serializer_class = AuthorSerializer
    permission_classes = [IsAdminRole]
    pagination_class = None
    queryset = Author.objects.all()


class AuthorAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Переименование/удаление автора. Удаление запрещено, пока автор
    привязан хотя бы к одной книге (ТЗ)."""

    serializer_class = AuthorSerializer
    permission_classes = [IsAdminRole]
    queryset = Author.objects.all()

    def destroy(self, request, *args, **kwargs):
        author = self.get_object()
        if author.books.exists():
            return Response(
                {"detail": "Нельзя удалить автора, привязанного к книгам."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return super().destroy(request, *args, **kwargs)
