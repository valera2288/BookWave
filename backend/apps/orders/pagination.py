from rest_framework.pagination import PageNumberPagination


class AdminOrderPagination(PageNumberPagination):
    """Список заказов в админ-панели — по 25 записей на страницу (ТЗ)."""

    page_size = 25
