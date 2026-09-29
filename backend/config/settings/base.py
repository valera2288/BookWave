"""
Общие настройки Django для всех окружений.
Окружение выбирается через DJANGO_ENV (dev/prod) в config/settings/__init__.py.
"""

import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

# backend/config/settings/base.py -> parents[2] == backend/
BASE_DIR = Path(__file__).resolve().parents[2]

load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv("SECRET_KEY", "django-insecure-change-me-in-.env")

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
]

# Domain-приложения — по одному на модуль из ARCHITECTURE.md
LOCAL_APPS = [
    "apps.common",
    "apps.users",
    "apps.catalog",
    "apps.files",
    "apps.favorites",
    "apps.cart",
    "apps.orders",
    "apps.promo",
    "apps.library",
    "apps.bookmarks",
    "apps.reviews",
    "apps.reports",
    "apps.notifications",
    "apps.banners",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB", "bookwave"),
        "USER": os.getenv("POSTGRES_USER", "bookwave"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "bookwave"),
        "HOST": os.getenv("POSTGRES_HOST", "localhost"),
        "PORT": os.getenv("POSTGRES_PORT", "5432"),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "apps.users.validators.ContainsDigitValidator"},
]

LANGUAGE_CODE = "ru"
# Даты по-прежнему хранятся в UTC (USE_TZ), но границы суток в отчётах о
# продажах и фильтре заказов по датам считаются в поясе магазина.
TIME_ZONE = os.getenv("TIME_ZONE", "Europe/Moscow")
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# Локальное файловое хранилище (см. ARCHITECTURE.md — S3 отложен)
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

# Внутренняя nginx-location для X-Accel-Redirect при раздаче файлов книг
# (ARCHITECTURE.md, «Раздача файлов книг») — Django сам байты не отдаёт вне
# DEBUG. Пример конфигурации для будущего деплоя (Phase 11):
#   location /protected-media/ {
#       internal;
#       alias /path/to/media/;
#   }
PROTECTED_MEDIA_INTERNAL_LOCATION = os.getenv(
    "PROTECTED_MEDIA_INTERNAL_LOCATION", "/protected-media/"
)

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

AUTH_USER_MODEL = "users.User"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "apps.users.authentication.TokenVersionJWTAuthentication",
    ),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
}

CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("CORS_ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]

# Базовые URL для ссылок в письмах. Обе ссылки открывают мобильное
# приложение напрямую через custom URI scheme (см. AndroidManifest.xml /
# Info.plist в mobile/) — не Android App Links / iOS Universal Links,
# т.к. те требуют верификации через файл на реальном HTTPS-домене
# (assetlinks.json / apple-app-site-association), которого у учебного
# проекта нет; custom scheme работает без хостинга и домена. Раньше здесь
# был плейсхолдер https://bookwave.app/... — несуществующий домен, никак
# не связанный с реальным адресом бэкенда, так что ссылка вела в никуда.
FRONTEND_CONFIRM_EMAIL_URL_BASE = os.getenv(
    "FRONTEND_CONFIRM_EMAIL_URL_BASE", "bookwave://confirm-email"
)
FRONTEND_PASSWORD_RESET_URL_BASE = os.getenv(
    "FRONTEND_PASSWORD_RESET_URL_BASE", "bookwave://reset-password"
)

DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", "no-reply@bookwave.app")
