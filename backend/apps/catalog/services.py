from django.db.models import Avg, Count, Q, QuerySet

from apps.favorites.models import Favorite
from apps.library.models import LibraryEntry
from apps.orders.models import Order

from .models import Book, Genre

RECOMMENDATIONS_LIMIT = 20
TOP_SELLERS_LIMIT = 10


def annotate_ratings(queryset: QuerySet[Book]) -> QuerySet[Book]:
    """Средний рейтинг и число оценок, без учёта отзывов, скрытых модератором.

    `distinct=True` в Count — на случай, если queryset уже соединён с
    genres/authors по другому фильтру (иначе JOIN размножил бы строки
    отзывов и завысил rating_count)."""
    return queryset.annotate(
        average_rating=Avg("reviews__rating", filter=Q(reviews__is_hidden=False)),
        rating_count=Count("reviews", filter=Q(reviews__is_hidden=False), distinct=True),
    )


def get_recommendations(user) -> QuerySet[Book]:
    """Без ML: книги тех же жанров, что в избранном/библиотеке пользователя,
    за вычетом уже купленного (см. ARCHITECTURE.md, «Рекомендации на главной»).
    Возвращает неаннотированный, неограниченный queryset — `annotate_ratings`
    и срез по количеству применяет вызывающая сторона (порядок операций в
    Django важен: annotate/filter нельзя делать после среза)."""
    owned_book_ids = set(
        LibraryEntry.objects.filter(user=user).values_list("book_id", flat=True)
    )
    favorite_book_ids = Favorite.objects.filter(user=user).values_list("book_id", flat=True)
    source_book_ids = owned_book_ids | set(favorite_book_ids)

    if not source_book_ids:
        return Book.objects.none()

    genre_ids = Genre.objects.filter(books__id__in=source_book_ids).values_list(
        "id", flat=True
    )

    return (
        Book.objects.filter(is_active=True, genres__id__in=genre_ids)
        .exclude(id__in=owned_book_ids)
        .distinct()
        .order_by("-created_at")
    )


def get_top_sellers() -> QuerySet[Book]:
    """Блок «Топ продаж» на главной (ТЗ): книги по числу проданных
    экземпляров среди оплаченных заказов, без ML. `distinct=True` в Count —
    та же причина, что в `annotate_ratings`: queryset комбинируется с ней
    вызывающей стороной (второй Count на reviews не должен задвоить это
    подсчёт через общий JOIN). Книги без единой оплаченной продажи в
    выдачу не попадают. Неаннотированный, неограниченный queryset — срез
    по количеству применяет вызывающая сторона."""
    return (
        Book.objects.filter(is_active=True)
        .annotate(
            sales_count=Count(
                "order_items",
                filter=Q(order_items__order__status=Order.Status.PAID),
                distinct=True,
            )
        )
        .filter(sales_count__gt=0)
        .order_by("-sales_count", "-created_at")
    )
