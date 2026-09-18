from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.catalog.models import Book
from apps.catalog.services import annotate_ratings
from apps.library.models import LibraryEntry
from apps.users.models import User

from .models import Review
from .views import MyReviewView, ReviewListView


def _make_user(email):
    return User.objects.create_user(email=email, password="testpass123", name="Reader")


def _make_book(isbn, **overrides):
    defaults = {"title": f"Book {isbn}", "price": Decimal("100.00"), "isbn": isbn}
    defaults.update(overrides)
    return Book.objects.create(**defaults)


class MyReviewViewTests(TestCase):
    """ТЗ: отзыв только для книги из своей библиотеки, один на книгу,
    с возможностью последующего редактирования/удаления."""

    def test_post_without_purchase_is_forbidden(self):
        user = _make_user("nobuyer@test.local")
        book = _make_book("4000000000001")

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5, "text": "Отлично"}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 403)
        self.assertEqual(Review.objects.count(), 0)

    def test_post_creates_review_for_owned_book(self):
        user = _make_user("owner@test.local")
        book = _make_book("4000000000002")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/",
            {"rating": 4, "text": "Хорошая книга, всем советую"},
            format="json",
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 201)
        self.assertEqual(Review.objects.get().rating, 4)

    def test_rating_out_of_range_is_rejected(self):
        user = _make_user("outofrange@test.local")
        book = _make_book("4000000000011")
        LibraryEntry.objects.create(user=user, book=book)

        for bad_rating in (0, 6, 999, -5):
            request = APIRequestFactory().post(
                f"/api/reviews/book/{book.id}/mine/", {"rating": bad_rating}, format="json"
            )
            force_authenticate(request, user=user)
            response = MyReviewView.as_view()(request, book_id=book.id)
            self.assertEqual(response.status_code, 400, f"rating={bad_rating} should be rejected")
        self.assertEqual(Review.objects.count(), 0)

    def test_empty_text_is_allowed(self):
        """Текст необязателен — отзыв может быть только оценкой."""
        user = _make_user("ratingonly@test.local")
        book = _make_book("4000000000012")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5, "text": ""}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 201)

    def test_too_short_text_is_rejected(self):
        user = _make_user("shorttext@test.local")
        book = _make_book("4000000000013")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5, "text": "норм"}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Review.objects.count(), 0)

    def test_too_long_text_is_rejected(self):
        user = _make_user("longtext@test.local")
        book = _make_book("4000000000014")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5, "text": "а" * 2001}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Review.objects.count(), 0)

    def test_second_post_is_rejected(self):
        user = _make_user("twice@test.local")
        book = _make_book("4000000000003")
        LibraryEntry.objects.create(user=user, book=book)
        Review.objects.create(user=user, book=book, rating=3, text="Норм")

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5, "text": "Ещё раз"}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Review.objects.count(), 1)

    def test_race_between_check_and_save_returns_400_not_500(self):
        """Гонка: две одновременные попытки от одного пользователя (два
        устройства/сессии) обе проходят `.exists()` до того, как первая
        закоммитится. Симулируем это, подменяя `.exists()` на False, пока
        отзыв уже реально существует в БД — `IntegrityError` от уникального
        ограничения должен превращаться в чистый 400, а не падать 500-й."""
        user = _make_user("racer@test.local")
        book = _make_book("4000000000016")
        LibraryEntry.objects.create(user=user, book=book)
        Review.objects.create(user=user, book=book, rating=3, text="Уже есть отзыв тут")

        request = APIRequestFactory().post(
            f"/api/reviews/book/{book.id}/mine/",
            {"rating": 5, "text": "Вторая попытка при гонке"},
            format="json",
        )
        force_authenticate(request, user=user)

        with patch("apps.reviews.views.Review.objects.filter") as mock_filter:
            mock_filter.return_value.exists.return_value = False
            response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Review.objects.filter(user=user, book=book).count(), 1)

    def test_patch_updates_own_review(self):
        user = _make_user("editor@test.local")
        book = _make_book("4000000000004")
        LibraryEntry.objects.create(user=user, book=book)
        Review.objects.create(user=user, book=book, rating=2, text="Так себе")

        request = APIRequestFactory().patch(
            f"/api/reviews/book/{book.id}/mine/",
            {"rating": 5, "text": "Пересмотрел мнение"},
            format="json",
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 200)
        review = Review.objects.get()
        self.assertEqual(review.rating, 5)
        self.assertEqual(review.text, "Пересмотрел мнение")

    def test_patch_on_missing_review_is_404(self):
        user = _make_user("noreview@test.local")
        book = _make_book("4000000000005")
        LibraryEntry.objects.create(user=user, book=book)

        request = APIRequestFactory().patch(
            f"/api/reviews/book/{book.id}/mine/", {"rating": 5}, format="json"
        )
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 404)

    def test_delete_removes_own_review(self):
        user = _make_user("deleter@test.local")
        book = _make_book("4000000000006")
        LibraryEntry.objects.create(user=user, book=book)
        Review.objects.create(user=user, book=book, rating=1, text="Не понравилось")

        request = APIRequestFactory().delete(f"/api/reviews/book/{book.id}/mine/")
        force_authenticate(request, user=user)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 204)
        self.assertEqual(Review.objects.count(), 0)

    def test_cannot_delete_or_edit_another_users_review(self):
        owner = _make_user("realowner@test.local")
        stranger = _make_user("stranger@test.local")
        book = _make_book("4000000000007")
        LibraryEntry.objects.create(user=owner, book=book)
        Review.objects.create(user=owner, book=book, rating=5, text="Моё")

        request = APIRequestFactory().delete(f"/api/reviews/book/{book.id}/mine/")
        force_authenticate(request, user=stranger)
        response = MyReviewView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 404)
        self.assertEqual(Review.objects.count(), 1)


class ReviewListViewTests(TestCase):
    def test_hidden_reviews_are_excluded(self):
        author = _make_user("visible@test.local")
        moderated = _make_user("hidden@test.local")
        book = _make_book("4000000000008")
        Review.objects.create(user=author, book=book, rating=5, text="Видно")
        Review.objects.create(user=moderated, book=book, rating=1, text="Скрыто", is_hidden=True)

        request = APIRequestFactory().get(f"/api/reviews/book/{book.id}/")
        response = ReviewListView.as_view()(request, book_id=book.id)

        self.assertEqual(response.status_code, 200)
        results = response.data["results"]
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["text"], "Видно")

    def test_is_mine_flag_reflects_requesting_user(self):
        user = _make_user("mine@test.local")
        other = _make_user("other@test.local")
        book = _make_book("4000000000009")
        Review.objects.create(user=user, book=book, rating=4, text="Моё")

        request = APIRequestFactory().get(f"/api/reviews/book/{book.id}/")
        force_authenticate(request, user=other)
        response = ReviewListView.as_view()(request, book_id=book.id)

        self.assertFalse(response.data["results"][0]["is_mine"])


class AverageRatingRecalculationTests(TestCase):
    """ТЗ: средний рейтинг пересчитывается автоматически при добавлении,
    изменении или удалении отзыва — здесь это чистая функция annotate_ratings
    без денормализованного хранимого поля, так что «пересчёт» происходит
    сам собой на каждом чтении."""

    def test_average_updates_as_reviews_change(self):
        user1 = _make_user("rater1@test.local")
        user2 = _make_user("rater2@test.local")
        book = _make_book("4000000000010")

        Review.objects.create(user=user1, book=book, rating=2)
        annotated = annotate_ratings(Book.objects.filter(id=book.id)).get()
        self.assertEqual(annotated.average_rating, 2)
        self.assertEqual(annotated.rating_count, 1)

        review2 = Review.objects.create(user=user2, book=book, rating=4)
        annotated = annotate_ratings(Book.objects.filter(id=book.id)).get()
        self.assertEqual(annotated.average_rating, 3)
        self.assertEqual(annotated.rating_count, 2)

        review2.delete()
        annotated = annotate_ratings(Book.objects.filter(id=book.id)).get()
        self.assertEqual(annotated.average_rating, 2)
        self.assertEqual(annotated.rating_count, 1)
