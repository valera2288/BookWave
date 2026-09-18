from rest_framework.pagination import PageNumberPagination


class PublicCatalogPagination(PageNumberPagination):
    """Каталог для читателей — по 20 книг на страницу (ТЗ)."""

    page_size = 20


class AdminCatalogPagination(PageNumberPagination):
    """Списки в админ-панели — по 25 записей на страницу (ТЗ)."""

    page_size = 25
