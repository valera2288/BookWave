from django.db.models import Prefetch
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalog.models import Book
from apps.catalog.services import annotate_ratings

from .models import LibraryEntry
from .serializers import LibraryEntrySerializer, ProgressUpdateSerializer
from .services import apply_progress_update


def _library_queryset(user):
    """Записи библиотеки с аннотированными рейтингами книг — без этого
    `BookListSerializer` молча теряет average_rating/rating_count (DRF
    считает read_only-поле без атрибута необязательным и пропускает его),
    а мобильный клиент падает на разборе JSON без `rating_count` (см.
    аналогичный докстринг в `apps/orders/views.py`)."""
    annotated_books = annotate_ratings(Book.objects.all()).prefetch_related("authors")
    return LibraryEntry.objects.filter(user=user).prefetch_related(
        Prefetch("book", queryset=annotated_books)
    )


class LibraryListView(generics.ListAPIView):
    """«Моя библиотека» (ТЗ): все купленные книги с прогрессом чтения."""

    serializer_class = LibraryEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return _library_queryset(self.request.user).order_by("-added_at")


class LibraryDetailView(APIView):
    """Одна запись библиотеки: GET — точка входа в читалку (404, если книга
    не куплена, до открытия защищённого файлового эндпоинта); PATCH —
    синхронизация прогресса чтения между устройствами; DELETE — удаление
    книги из личной библиотеки (ТЗ, «Отказы из-за некорректных действий
    пользователя»: необратимое действие, клиент обязан запросить
    подтверждение перед вызовом)."""

    permission_classes = [IsAuthenticated]

    def _get_entry(self, request, book_id):
        return get_object_or_404(_library_queryset(request.user), book_id=book_id)

    def get(self, request, book_id):
        entry = self._get_entry(request, book_id)
        return Response(LibraryEntrySerializer(entry).data)

    def delete(self, request, book_id):
        entry = self._get_entry(request, book_id)
        entry.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def patch(self, request, book_id):
        entry = self._get_entry(request, book_id)
        serializer = ProgressUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        entry = apply_progress_update(
            entry,
            serializer.validated_data["progress"],
            serializer.validated_data["progress_updated_at"],
        )
        return Response(LibraryEntrySerializer(entry).data)
