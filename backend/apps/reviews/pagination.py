from rest_framework.pagination import PageNumberPagination


class ReviewPagination(PageNumberPagination):
    """Список отзывов под карточкой книги — «с возможностью пролистывания» (ТЗ)."""

    page_size = 10


class AdminReviewPagination(PageNumberPagination):
    """Модерация отзывов в админ-панели — по 25 записей на страницу."""

    page_size = 25
