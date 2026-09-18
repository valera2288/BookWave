from decimal import Decimal

from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.catalog.models import Book
from apps.library.models import LibraryEntry
from apps.users.models import User

from .models import Bookmark
from .views import BookmarkListCreateView


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Reader")


def _make_book(isbn):
    return Book.objects.create(title=f"Book {isbn}", price=Decimal("100.00"), isbn=isbn)


class BookmarkListCreateViewTests(TestCase):
    """Закладки — только для купленных книг (ТЗ, «Требования к контролю
    доступа к файлам книг» распространяется и на закладки)."""

    def _post(self, user, book_id, position="epubcfi(/6/4!/4/2/1:0)"):
        request = APIRequestFactory().post(
            "/api/bookmarks/", {"book_id": book_id, "position": position}, format="json"
        )
        force_authenticate(request, user=user)
        return BookmarkListCreateView.as_view()(request)

    def test_bookmark_on_book_not_owned_is_404(self):
        user = _make_user("u1@test.local")
        book = _make_book("4000000000001")

        response = self._post(user, book.id)

        self.assertEqual(response.status_code, 404)
        self.assertEqual(Bookmark.objects.count(), 0)

    def test_bookmark_on_owned_book_is_created(self):
        user = _make_user("u2@test.local")
        book = _make_book("4000000000002")
        LibraryEntry.objects.create(user=user, book=book)

        response = self._post(user, book.id)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(Bookmark.objects.filter(user=user, book=book).count(), 1)

    def test_list_is_scoped_to_current_user_and_optional_book_filter(self):
        user = _make_user("u3@test.local")
        other = _make_user("u4@test.local")
        book_a = _make_book("4000000000003")
        book_b = _make_book("4000000000004")
        LibraryEntry.objects.create(user=user, book=book_a)
        LibraryEntry.objects.create(user=user, book=book_b)
        LibraryEntry.objects.create(user=other, book=book_a)

        Bookmark.objects.create(user=user, book=book_a, position="p1")
        Bookmark.objects.create(user=user, book=book_b, position="p2")
        Bookmark.objects.create(user=other, book=book_a, position="p3")

        request = APIRequestFactory().get(f"/api/bookmarks/?book_id={book_a.id}")
        force_authenticate(request, user=user)
        response = BookmarkListCreateView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["position"], "p1")
