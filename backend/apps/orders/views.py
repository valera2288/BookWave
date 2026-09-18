from django.db.models import Count, Prefetch, Q
from django.utils.dateparse import parse_date
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalog.models import Book
from apps.catalog.services import annotate_ratings
from apps.users.permissions import IsAdminRole

from .export import export_orders_xlsx
from .models import Order
from .pagination import AdminOrderPagination
from .serializers import (
    CheckoutSerializer,
    OrderAdminDetailSerializer,
    OrderAdminListSerializer,
    OrderDetailSerializer,
    OrderListSerializer,
    OrderStatusUpdateSerializer,
)
from .services import CheckoutError, checkout

ORDER_STATUS_VALUES = {choice for choice, _ in Order.Status.choices}


def _order_detail_queryset(user):
    """Заказы пользователя с аннотированными рейтингами книг в позициях —
    без этого `BookListSerializer` молча теряет average_rating/rating_count
    (DRF считает read_only-поле без атрибута необязательным и пропускает
    его), а мобильный клиент их не подстраховывает `?` при парсинге."""
    annotated_books = annotate_ratings(Book.objects.all()).prefetch_related("authors")
    return Order.objects.filter(user=user).prefetch_related(
        Prefetch("items__book", queryset=annotated_books)
    )


class CheckoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CheckoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            order = checkout(
                request.user,
                card_number=serializer.validated_data["card_number"],
                promo_code=serializer.validated_data.get("promo_code") or None,
            )
        except CheckoutError as e:
            return Response({"detail": str(e)}, status=e.status_code)

        order = _order_detail_queryset(request.user).get(id=order.id)
        return Response(OrderDetailSerializer(order).data, status=status.HTTP_201_CREATED)


class OrderListView(generics.ListAPIView):
    """История заказов, от новых к старым (ТЗ)."""

    serializer_class = OrderListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return (
            Order.objects.filter(user=self.request.user)
            .annotate(item_count=Count("items"))
            .order_by("-created_at")
        )


class OrderDetailView(generics.RetrieveAPIView):
    serializer_class = OrderDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return _order_detail_queryset(self.request.user)


def _filtered_admin_orders(params):
    """Общий фильтр списка заказов для админки: поиск по номеру заказа/e-mail,
    статус, диапазон дат — используется и списком, и Excel-экспортом таблицы
    (ТЗ, экран списка заказов), чтобы оба всегда фильтровали одинаково."""
    queryset = Order.objects.select_related("user").annotate(item_count=Count("items"))

    search = params.get("search", "").strip().lstrip("#")
    if search:
        search_filter = Q(user__email__icontains=search)
        if search.isdigit():
            search_filter |= Q(id=int(search))
        queryset = queryset.filter(search_filter)

    status_param = params.get("status")
    if status_param in ORDER_STATUS_VALUES:
        queryset = queryset.filter(status=status_param)

    date_from = parse_date(params.get("date_from", ""))
    if date_from:
        queryset = queryset.filter(created_at__date__gte=date_from)

    date_to = parse_date(params.get("date_to", ""))
    if date_to:
        queryset = queryset.filter(created_at__date__lte=date_to)

    return queryset.order_by("-created_at")


class OrderAdminListView(generics.ListAPIView):
    """Список заказов в админ-панели (ТЗ): поиск по номеру заказа и e-mail
    покупателя, фильтр по статусу и диапазону дат, пагинация по 25."""

    serializer_class = OrderAdminListSerializer
    permission_classes = [IsAdminRole]
    pagination_class = AdminOrderPagination

    def get_queryset(self):
        return _filtered_admin_orders(self.request.query_params)


class OrderAdminExportView(APIView):
    """Экспорт таблицы заказов в Excel (ТЗ, экран списка заказов): те же
    колонки, что в таблице на экране (номер, покупатель, сумма, статус,
    дата), с учётом текущих фильтров/поиска — без агрегации, в отличие от
    apps.reports (это разные требования ТЗ, см. п. 98 и п. 230-232)."""

    permission_classes = [IsAdminRole]

    def get(self, request):
        orders = _filtered_admin_orders(request.query_params)
        return export_orders_xlsx(orders)


class OrderAdminDetailView(generics.RetrieveUpdateAPIView):
    """Детальный просмотр заказа администратором + смена статуса через
    выпадающий список (ТЗ). Состав заказа постфактум не редактируется."""

    permission_classes = [IsAdminRole]
    http_method_names = ["get", "patch"]

    def get_queryset(self):
        annotated_books = annotate_ratings(Book.objects.all()).prefetch_related("authors")
        return Order.objects.select_related("user").prefetch_related(
            Prefetch("items__book", queryset=annotated_books)
        )

    def get_serializer_class(self):
        if self.request.method == "PATCH":
            return OrderStatusUpdateSerializer
        return OrderAdminDetailSerializer

    def update(self, request, *args, **kwargs):
        # `UpdateModelMixin.update()` по умолчанию отвечает данными узкого
        # write-сериализатора (`{"status": "..."}`) — без этого переопределения
        # фронт получал вместо полного заказа объект без `items`/`buyer_*`
        # и падал на `order.items.map(...)`, теряя уже отрисованные данные.
        super().update(request, *args, **kwargs)
        instance = self.get_object()
        return Response(OrderAdminDetailSerializer(instance).data)
