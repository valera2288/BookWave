import secrets
from datetime import timedelta

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.utils import timezone

from .validators import validate_avatar_file

PASSWORD_RESET_TOKEN_LIFETIME = timedelta(minutes=30)
EMAIL_CONFIRMATION_TOKEN_LIFETIME = timedelta(days=3)


def generate_token() -> str:
    return secrets.token_urlsafe(32)


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, name, **extra_fields):
        if not email:
            raise ValueError("Email обязателен")
        email = self.normalize_email(email)
        user = self.model(email=email, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, name="", **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, name, **extra_fields)

    def create_superuser(self, email, password=None, name="", **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", User.Role.ADMIN)
        extra_fields.setdefault("email_verified", True)
        return self._create_user(email, password, name, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        READER = "reader", "Читатель"
        ADMIN = "admin", "Администратор"

    class Theme(models.TextChoices):
        LIGHT = "light", "Светлая"
        DARK = "dark", "Тёмная"
        SYSTEM = "system", "Системная"

    class Language(models.TextChoices):
        RU = "ru", "Русский"
        EN = "en", "English"

    email = models.EmailField(unique=True)
    name = models.CharField(max_length=50)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.READER)
    avatar = models.ImageField(
        upload_to="avatars/", null=True, blank=True, validators=[validate_avatar_file]
    )
    theme = models.CharField(max_length=10, choices=Theme.choices, default=Theme.SYSTEM)
    language = models.CharField(max_length=5, choices=Language.choices, default=Language.RU)
    email_verified = models.BooleanField(default=False)
    token_version = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["name"]

    class Meta:
        db_table = "users"

    def __str__(self):
        return self.email


class EmailConfirmationToken(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="email_confirmation_tokens"
    )
    token = models.CharField(max_length=64, unique=True, default=generate_token)
    # Заполнен только для флоу "смена e-mail" (не для подтверждения при
    # регистрации) — на этот адрес уходит письмо с подтверждением, и он же
    # становится новым `User.email` после успешного подтверждения.
    new_email = models.EmailField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "email_confirmation_tokens"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + EMAIL_CONFIRMATION_TOKEN_LIFETIME
        super().save(*args, **kwargs)

    @property
    def is_valid(self) -> bool:
        return self.used_at is None and timezone.now() < self.expires_at


class PasswordResetToken(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="password_reset_tokens"
    )
    token = models.CharField(max_length=64, unique=True, default=generate_token)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "password_reset_tokens"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + PASSWORD_RESET_TOKEN_LIFETIME
        super().save(*args, **kwargs)

    @property
    def is_valid(self) -> bool:
        return self.used_at is None and timezone.now() < self.expires_at
