from io import BytesIO

from django.core import mail
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image as PILImage
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from .models import EmailConfirmationToken, PasswordResetToken, User
from .views import (
    LOGIN_ATTEMPT_LIMIT,
    PASSWORD_RESET_REQUEST_LIMIT,
)

VALID_PASSWORD = "Str0ngPass!"


class RegisterTests(APITestCase):
    def setUp(self):
        cache.clear()

    def test_register_creates_user_and_returns_tokens(self):
        url = reverse("register")
        response = self.client.post(
            url,
            {
                "email": "reader@example.com",
                "name": "Читатель",
                "password": VALID_PASSWORD,
                "accept_terms": True,
            },
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

        user = User.objects.get(email="reader@example.com")
        self.assertFalse(user.email_verified)
        self.assertTrue(user.check_password(VALID_PASSWORD))

        access = AccessToken(response.data["access"])
        self.assertEqual(access["token_version"], user.token_version)

        self.assertEqual(len(mail.outbox), 1)
        self.assertTrue(EmailConfirmationToken.objects.filter(user=user).exists())

    def test_register_rejects_weak_password(self):
        url = reverse("register")
        response = self.client.post(
            url,
            {
                "email": "weak@example.com",
                "name": "Читатель",
                "password": "aaaaaaaa",  # без цифры
                "accept_terms": True,
            },
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(email="weak@example.com").exists())

    def test_register_requires_accepted_terms(self):
        url = reverse("register")
        response = self.client.post(
            url,
            {
                "email": "noterms@example.com",
                "name": "Читатель",
                "password": VALID_PASSWORD,
                "accept_terms": False,
            },
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(email="noterms@example.com").exists())


class LoginLockoutTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="login@example.com", password=VALID_PASSWORD, name="Читатель"
        )
        self.url = reverse("login")

    def test_login_success_returns_tokens(self):
        response = self.client.post(
            self.url, {"email": self.user.email, "password": VALID_PASSWORD}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_login_locks_out_after_repeated_failures(self):
        for _ in range(LOGIN_ATTEMPT_LIMIT):
            response = self.client.post(
                self.url, {"email": self.user.email, "password": "wrong-password"}
            )
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

        locked_response = self.client.post(
            self.url, {"email": self.user.email, "password": VALID_PASSWORD}
        )

        self.assertEqual(locked_response.status_code, status.HTTP_423_LOCKED)

    def test_successful_login_resets_attempt_counter(self):
        self.client.post(self.url, {"email": self.user.email, "password": "wrong-password"})
        self.client.post(self.url, {"email": self.user.email, "password": "wrong-password"})

        ok_response = self.client.post(
            self.url, {"email": self.user.email, "password": VALID_PASSWORD}
        )
        self.assertEqual(ok_response.status_code, status.HTTP_200_OK)

        cache_key = f"login_attempts:{self.user.email}"
        self.assertIsNone(cache.get(cache_key))


class TokenRevocationTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="secure@example.com", password=VALID_PASSWORD, name="Читатель"
        )
        login = self.client.post(
            reverse("login"), {"email": self.user.email, "password": VALID_PASSWORD}
        )
        self.old_access = login.data["access"]

    def test_old_access_token_rejected_after_password_change(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.old_access}")
        change_response = self.client.post(
            reverse("change_password"),
            {
                "current_password": VALID_PASSWORD,
                "new_password": "AnotherStr0ng!",
                "new_password2": "AnotherStr0ng!",
            },
        )
        self.assertEqual(change_response.status_code, status.HTTP_200_OK)

        self.user.refresh_from_db()
        self.assertEqual(self.user.token_version, 1)

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.old_access}")
        reuse_response = self.client.post(
            reverse("change_password"),
            {
                "current_password": "AnotherStr0ng!",
                "new_password": VALID_PASSWORD,
                "new_password2": VALID_PASSWORD,
            },
        )
        self.assertEqual(reuse_response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_response_includes_fresh_tokens_valid_for_current_device(self):
        """ТЗ: смена пароля завершает "прочие" сессии — то есть само
        устройство, с которого её выполнили, должно остаться в сессии.
        `ChangePasswordView` должен выдать новую пару токенов (как
        `LoginView`), иначе текущее устройство тоже вылетит из аккаунта,
        поскольку старый access/refresh несут прежний `token_version`."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.old_access}")
        response = self.client.post(
            reverse("change_password"),
            {
                "current_password": VALID_PASSWORD,
                "new_password": "AnotherStr0ng!",
                "new_password2": "AnotherStr0ng!",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

        new_access = AccessToken(response.data["access"])
        self.user.refresh_from_db()
        self.assertEqual(new_access["token_version"], self.user.token_version)

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        me_response = self.client.get(reverse("me"))
        self.assertEqual(me_response.status_code, status.HTTP_200_OK)

    def test_change_password_rejects_wrong_current_password(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.old_access}")
        response = self.client.post(
            reverse("change_password"),
            {
                "current_password": "not-the-password",
                "new_password": "AnotherStr0ng!",
                "new_password2": "AnotherStr0ng!",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class EmailConfirmationTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="confirm@example.com", password=VALID_PASSWORD, name="Читатель"
        )

    def test_valid_token_confirms_email(self):
        token = EmailConfirmationToken.objects.create(user=self.user)
        response = self.client.post(
            reverse("confirm_email", kwargs={"token": token.token})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.email_verified)

    def test_unknown_token_rejected(self):
        response = self.client.post(
            reverse("confirm_email", kwargs={"token": "does-not-exist"})
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class PasswordResetTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="reset@example.com", password=VALID_PASSWORD, name="Читатель"
        )
        self.request_url = reverse("password_reset")
        self.confirm_url = reverse("password_reset_confirm")

    def test_request_for_existing_user_sends_email(self):
        response = self.client.post(self.request_url, {"email": self.user.email})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 1)
        self.assertTrue(PasswordResetToken.objects.filter(user=self.user).exists())

    def test_request_for_unknown_user_returns_generic_response_without_email(self):
        response = self.client.post(self.request_url, {"email": "ghost@example.com"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 0)

    def test_request_is_rate_limited(self):
        for _ in range(PASSWORD_RESET_REQUEST_LIMIT):
            response = self.client.post(self.request_url, {"email": self.user.email})
            self.assertEqual(response.status_code, status.HTTP_200_OK)

        limited_response = self.client.post(self.request_url, {"email": self.user.email})
        self.assertEqual(limited_response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)

    def test_confirm_changes_password_and_revokes_sessions(self):
        reset_token = PasswordResetToken.objects.create(user=self.user)

        response = self.client.post(
            self.confirm_url,
            {
                "token": reset_token.token,
                "new_password": "AnotherStr0ng!",
                "new_password2": "AnotherStr0ng!",
            },
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("AnotherStr0ng!"))
        self.assertEqual(self.user.token_version, 1)

        reset_token.refresh_from_db()
        self.assertIsNotNone(reset_token.used_at)

    def test_confirm_rejects_reused_token(self):
        reset_token = PasswordResetToken.objects.create(user=self.user)
        payload = {
            "token": reset_token.token,
            "new_password": "AnotherStr0ng!",
            "new_password2": "AnotherStr0ng!",
        }

        first = self.client.post(self.confirm_url, payload)
        self.assertEqual(first.status_code, status.HTTP_200_OK)

        second = self.client.post(self.confirm_url, payload)
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_confirm_rejects_mismatched_passwords(self):
        reset_token = PasswordResetToken.objects.create(user=self.user)

        response = self.client.post(
            self.confirm_url,
            {
                "token": reset_token.token,
                "new_password": "AnotherStr0ng!",
                "new_password2": "Different1!",
            },
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class EmailChangeTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="owner@example.com", password=VALID_PASSWORD, name="Читатель"
        )
        self.other_user = User.objects.create_user(
            email="taken@example.com", password=VALID_PASSWORD, name="Другой"
        )
        login = self.client.post(
            reverse("login"), {"email": self.user.email, "password": VALID_PASSWORD}
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_request_sends_confirmation_to_new_address_only(self):
        response = self.client.post(reverse("change_email"), {"new_email": "new@example.com"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ["new@example.com"])
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "owner@example.com")  # ещё не сменился

    def test_request_rejects_email_exceeding_model_max_length(self):
        """ТЗ 4.5.4: серверная валидация длины/диапазона входных данных —
        `new_email` должен быть ограничен так же, как `User.email`
        (max_length=254), иначе слишком длинный адрес падает 500-й на
        confirm вместо чистой 400-й здесь."""
        too_long = f"{'a' * 250}@example.com"  # длиннее 254 символов
        response = self.client.post(reverse("change_email"), {"new_email": too_long})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_request_rejects_email_already_taken(self):
        response = self.client.post(reverse("change_email"), {"new_email": self.other_user.email})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_confirm_changes_email(self):
        self.client.post(reverse("change_email"), {"new_email": "new@example.com"})
        token = EmailConfirmationToken.objects.get(user=self.user, new_email="new@example.com")

        response = self.client.post(reverse("confirm_email", kwargs={"token": token.token}))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "new@example.com")
        self.assertTrue(self.user.email_verified)

    def test_earlier_pending_request_invalidated_by_a_newer_one(self):
        """Пользователь передумал: запросил смену на A, затем на B. Старая
        ссылка на A (ещё "живая" — использованной не была, срок не истёк)
        не должна суметь молча откатить e-mail обратно на A после того,
        как пользователь подтвердил B."""
        self.client.post(reverse("change_email"), {"new_email": "first-choice@example.com"})
        stale_token = EmailConfirmationToken.objects.get(
            user=self.user, new_email="first-choice@example.com"
        )

        self.client.post(reverse("change_email"), {"new_email": "second-choice@example.com"})
        fresh_token = EmailConfirmationToken.objects.get(
            user=self.user, new_email="second-choice@example.com"
        )
        self.client.post(reverse("confirm_email", kwargs={"token": fresh_token.token}))
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "second-choice@example.com")

        response = self.client.post(reverse("confirm_email", kwargs={"token": stale_token.token}))

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "second-choice@example.com")  # не откатился на A

    def test_confirm_rejects_if_email_taken_by_someone_else_meanwhile(self):
        """Токен на смену e-mail живёт до 3 дней — за это время адрес мог
        занять другой пользователь (гонка), перепроверяем на подтверждении,
        не только на запросе."""
        self.client.post(reverse("change_email"), {"new_email": "raced@example.com"})
        token = EmailConfirmationToken.objects.get(user=self.user, new_email="raced@example.com")
        User.objects.create_user(
            email="raced@example.com", password=VALID_PASSWORD, name="Захватчик"
        )

        response = self.client.post(reverse("confirm_email", kwargs={"token": token.token}))

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "owner@example.com")


class ProfileUpdateTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="profile@example.com", password=VALID_PASSWORD, name="Читатель"
        )
        login = self.client.post(
            reverse("login"), {"email": self.user.email, "password": VALID_PASSWORD}
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_patch_updates_name_theme_language(self):
        response = self.client.patch(
            reverse("me"), {"name": "Новое Имя", "theme": "dark", "language": "en"}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name, "Новое Имя")
        self.assertEqual(self.user.theme, "dark")
        self.assertEqual(self.user.language, "en")

    def test_patch_rejects_invalid_name_length(self):
        response = self.client.patch(reverse("me"), {"name": "A"})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.user.refresh_from_db()
        self.assertEqual(self.user.name, "Читатель")

    def test_patch_does_not_touch_email(self):
        response = self.client.patch(reverse("me"), {"email": "hijacked@example.com"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "profile@example.com")

    def test_patch_uploads_avatar_and_returns_absolute_url(self):
        """`ImageField` без `context={"request": ...}` отдаёт относительный
        путь — на мобильном `Image.network(user.avatar)` с таким URL не
        загрузит картинку. Обложки книг уже абсолютные (generic-view сам
        прокидывает контекст) — профиль должен вести себя так же."""
        buffer = BytesIO()
        PILImage.new("RGB", (10, 10), color="red").save(buffer, format="PNG")
        avatar = SimpleUploadedFile("avatar.png", buffer.getvalue(), content_type="image/png")

        response = self.client.patch(reverse("me"), {"avatar": avatar}, format="multipart")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["avatar"].startswith("http://testserver/media/"))

    def test_get_also_returns_absolute_avatar_url(self):
        buffer = BytesIO()
        PILImage.new("RGB", (10, 10), color="blue").save(buffer, format="PNG")
        avatar = SimpleUploadedFile("avatar.png", buffer.getvalue(), content_type="image/png")
        self.client.patch(reverse("me"), {"avatar": avatar}, format="multipart")

        response = self.client.get(reverse("me"))

        self.assertTrue(response.data["avatar"].startswith("http://testserver/media/"))
