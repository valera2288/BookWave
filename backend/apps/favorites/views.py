from django.db.models import Prefetch
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.catalog.models import Book
from apps.catalog.services import annotate_ratings

from .models import Favorite
from .serializers import FavoriteSerializer


class FavoriteListCreateView(generics.ListCreateAPIView):
    """Список избранного пользователя и добавление книги (ТЗ: повторное
    добавление уже избранной книги не должно создавать дубликат/ошибку)."""

    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        annotated_books = annotate_ratings(Book.objects.all()).prefetch_related("authors")
        return (
            Favorite.objects.filter(user=self.request.user, book__is_active=True)
            .prefetch_related(Prefetch("book", queryset=annotated_books))
            .order_by("-created_at")
        )

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        book = serializer.validated_data["book"]
        favorite, created = Favorite.objects.get_or_create(user=request.user, book=book)
        favorite.book = (
            annotate_ratings(Book.objects.filter(id=book.id)).prefetch_related("authors").get()
        )
        output = self.get_serializer(favorite)
        return Response(
            output.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )


class FavoriteDeleteView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return get_object_or_404(
            Favorite, user=self.request.user, book_id=self.kwargs["book_id"]
        )
