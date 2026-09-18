from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.library.models import LibraryEntry
from apps.users.permissions import IsAdminRole

from .models import Review
from .pagination import AdminReviewPagination, ReviewPagination
from .serializers import (
    ReviewAdminSerializer,
    ReviewModerationSerializer,
    ReviewSerializer,
    ReviewWriteSerializer,
)


class ReviewListView(generics.ListAPIView):
    """Список отзывов о книге (карточка книги, ТЗ) — публичный; отзывы,
    скрытые модератором, не показываются никому, включая их автора."""

    serializer_class = ReviewSerializer
    permission_classes = [AllowAny]
    pagination_class = ReviewPagination

    def get_queryset(self):
        return Review.objects.filter(
            book_id=self.kwargs["book_id"], is_hidden=False
        ).select_related("user")


class MyReviewView(APIView):
    """Отзыв текущего пользователя о конкретной книге. ТЗ: один отзыв на
    книгу, оставить его можно только после покупки (запись в библиотеке),
    с возможностью последующего редактирования или удаления."""

    permission_classes = [IsAuthenticated]

    def _get_review(self, request, book_id):
        return get_object_or_404(Review, user=request.user, book_id=book_id)

    def get(self, request, book_id):
        review = self._get_review(request, book_id)
        return Response(ReviewSerializer(review, context={"request": request}).data)

    def post(self, request, book_id):
        if not LibraryEntry.objects.filter(user=request.user, book_id=book_id).exists():
            return Response(
                {"detail": "Отзыв можно оставить только на книгу из своей библиотеки."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if Review.objects.filter(user=request.user, book_id=book_id).exists():
            return Response(
                {"detail": "Вы уже оставили отзыв на эту книгу. Отредактируйте его."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = ReviewWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            # `atomic()`, а не голый try/except — без него пойманный
            # `IntegrityError` оставляет транзакцию в «broken» состоянии
            # (Postgres), и любой следующий запрос на этом соединении падает
            # с `TransactionManagementError`; savepoint внутри atomic() сам
            # откатывается при выходе по исключению.
            with transaction.atomic():
                review = serializer.save(user=request.user, book_id=book_id)
        except IntegrityError:
            # Гонка: два запроса от одного пользователя (два устройства/
            # сессии) оба прошли проверку `.exists()` выше до того, как
            # первый закоммитился — уникальность добивает на уровне БД.
            return Response(
                {"detail": "Вы уже оставили отзыв на эту книгу. Отредактируйте его."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            ReviewSerializer(review, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )

    def patch(self, request, book_id):
        review = self._get_review(request, book_id)
        serializer = ReviewWriteSerializer(review, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ReviewSerializer(review, context={"request": request}).data)

    def delete(self, request, book_id):
        review = self._get_review(request, book_id)
        review.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReviewAdminListView(generics.ListAPIView):
    """Модерация отзывов: полный список, включая уже скрытые (ТЗ)."""

    serializer_class = ReviewAdminSerializer
    permission_classes = [IsAdminRole]
    pagination_class = AdminReviewPagination

    def get_queryset(self):
        return Review.objects.select_related("user", "book").order_by("-created_at")


class ReviewAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Скрытие/показ отзыва модератором или его удаление (ТЗ) — без
    редактирования текста или оценки от чужого имени."""

    permission_classes = [IsAdminRole]
    queryset = Review.objects.select_related("user", "book")
    http_method_names = ["get", "patch", "delete"]

    def get_serializer_class(self):
        if self.request.method == "PATCH":
            return ReviewModerationSerializer
        return ReviewAdminSerializer

    def update(self, request, *args, **kwargs):
        # Аналогично OrderAdminDetailView: по умолчанию PATCH отвечал бы
        # только узким `{"is_hidden": ...}` без `id`/`book_title`/..., из-за
        # чего фронт не мог сматчить обновлённую запись в списке по id и
        # видел изменение только после полной перезагрузки списка.
        super().update(request, *args, **kwargs)
        instance = self.get_object()
        return Response(ReviewAdminSerializer(instance).data)
