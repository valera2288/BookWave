from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated

from apps.library.models import LibraryEntry

from .models import Bookmark
from .serializers import BookmarkSerializer


class BookmarkListCreateView(generics.ListCreateAPIView):
    """Закладки в тексте книги (ТЗ: «добавление и удаление закладок на
    текущей странице») — как и сама читалка, доступны только для купленных
    книг (ТЗ, «Требования к контролю доступа к файлам книг» идёт прямо перед
    требованиями к закладкам)."""

    serializer_class = BookmarkSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = Bookmark.objects.filter(user=self.request.user)
        book_id = self.request.query_params.get("book_id")
        if book_id:
            # Нечисловой book_id — просто пустой список, а не 500 от ORM.
            queryset = queryset.filter(book_id=book_id) if book_id.isdigit() else queryset.none()
        return queryset

    def perform_create(self, serializer):
        book = serializer.validated_data["book"]
        if not LibraryEntry.objects.filter(user=self.request.user, book=book).exists():
            raise NotFound("Книга недоступна для чтения.")
        serializer.save(user=self.request.user)


class BookmarkDeleteView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return get_object_or_404(Bookmark, user=self.request.user, pk=self.kwargs["pk"])
