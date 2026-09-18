from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.catalog.models import Book
from apps.users.models import User

from .models import LibraryEntry
from .services import apply_progress_update
from .views import LibraryDetailView, LibraryListView


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Reader")


def _make_book(isbn, **overrides):
    defaults = {"title": f"Book {isbn}", "price": Decimal("100.00"), "isbn": isbn}
    defaults.update(overrides)
    return Book.objects.create(**defaults)


class ApplyProgressUpdateTests(TestCase):
    def test_newer_client_timestamp_updates_progress(self):
        user = _make_user("u1@test.local")
        book = _make_book("3000000000001")
        entry = LibraryEntry.objects.create(user=user, book=book, progress=10)

        now = timezone.now()
        updated = apply_progress_update(entry, 50, now)

        self.assertEqual(updated.progress, 50)
        self.assertEqual(updated.progress_updated_at, now)

    def test_older_client_timestamp_is_ignored(self):
        user = _make_user("u2@test.local")
        book = _make_book("3000000000002")
        now = timezone.now()
        entry = LibraryEntry.objects.create(
            user=user, book=book, progress=80, progress_updated_at=now
        )

        stale = now - timedelta(hours=1)
        result = apply_progress_update(entry, 5, stale)

        self.assertEqual(result.progress, 80)
        self.assertEqual(result.progress_updated_at, now)

    def test_first_update_applies_even_without_prior_timestamp(self):
        user = _make_user("u3@test.local")
        book = _make_book("3000000000003")
        entry = LibraryEntry.objects.create(user=user, book=book, progress=0)

        now = timezone.now()
        result = apply_progress_update(entry, 15, now)

        self.assertEqual(result.progress, 15)
        self.assertEqual(result.progress_updated_at, now)


class LibraryDetailViewTests(TestCase):
    """Чужую (или некупленную) запись библиотеки не видно и не патчится —
    это же ворота в защищённую читалку (ТЗ, «Требования к контролю доступа
    к файлам книг»)."""

    def test_other_users_entry_is_404(self):
        owner = _make_user("owner@test.local")
        stranger = _make_user("stranger@test.local")
        book = _make_book("3000000000004")
        LibraryEntry.objects.create(user=owner, book=book)

        request = APIRequestFactory().get(f"/api/library/{book.id}/")
        force_authenticate(request, user=stranger)
        response = LibraryDetailView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 404)

    def test_not_purchased_book_is_404(self):
        user = _make_user("nobuyer@test.local")
        book = _make_book("3000000000005")

        request = APIRequestFactory().get(f"/api/library/{book.id}/")
        force_authenticate(request, user=user)
        response = LibraryDetailView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 404)

    def test_patch_applies_progress_and_returns_current_state(self):
        user = _make_user("patcher@test.local")
        book = _make_book("3000000000006")
        LibraryEntry.objects.create(user=user, book=book)

        now = timezone.now()
        request = APIRequestFactory().patch(
            f"/api/library/{book.id}/",
            {"progress": 42, "progress_updated_at": now.isoformat()},
            format="json",
        )
        force_authenticate(request, user=user)
        response = LibraryDetailView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["progress"], 42)


class LibraryEntrySerializationTests(TestCase):
    """Регресс: `BookListSerializer` молча роняет average_rating/rating_count
    без annotate_ratings() на queryset — мобильный клиент падает на разборе
    JSON без ключа `rating_count` (см. докстринг `_library_queryset`)."""

    def test_list_response_includes_rating_fields(self):
        user = _make_user("rater@test.local")
        book = _make_book("3000000000007")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().get("/api/library/")
        force_authenticate(request, user=user)
        response = LibraryListView.as_view()(request)

        self.assertEqual(response.status_code, 200)
        book_data = response.data["results"][0]["book"]
        self.assertIn("rating_count", book_data)
        self.assertIn("average_rating", book_data)

    def test_detail_response_includes_rating_fields(self):
        user = _make_user("rater2@test.local")
        book = _make_book("3000000000008")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().get(f"/api/library/{book.id}/")
        force_authenticate(request, user=user)
        response = LibraryDetailView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 200)
        self.assertIn("rating_count", response.data["book"])
        self.assertIn("average_rating", response.data["book"])
