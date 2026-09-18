from django.http import Http404
from django.shortcuts import get_object_or_404
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView

from apps.catalog.models import Book
from apps.library.models import LibraryEntry

from .services import FORMAT_CONTENT_TYPES, get_book_file_field, resolve_file_path, serve_file


class BookFileView(APIView):
    """Защищённая выдача файла книги (ТЗ: «Требования к контролю доступа к
    файлам книг») — один и тот же эндпоинт для полного файла и для
    ознакомительного фрагмента (ARCHITECTURE.md, «Раздача файлов книг»):
    владельцу (запись в library) отдаётся полный файл, всем остальным,
    включая неавторизованных гостей, — урезанная версия."""

    permission_classes = [AllowAny]

    def get(self, request, book_id, file_format):
        if file_format not in FORMAT_CONTENT_TYPES:
            raise Http404
        book = get_object_or_404(Book, pk=book_id)

        owns = (
            request.user.is_authenticated
            and LibraryEntry.objects.filter(user=request.user, book=book).exists()
        )
        if not book.is_active and not owns:
            raise Http404

        if not get_book_file_field(book, file_format):
            raise Http404

        path = resolve_file_path(book, file_format, owns=owns)
        return serve_file(
            path,
            filename=f"{book.title}.{file_format}",
            content_type=FORMAT_CONTENT_TYPES[file_format],
        )
