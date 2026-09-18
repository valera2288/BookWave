from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path("me/", views.MeView.as_view(), name="me"),
    path("register/", views.RegisterView.as_view(), name="register"),
    path("login/", views.LoginView.as_view(), name="login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path(
        "confirm-email/<str:token>/",
        views.ConfirmEmailView.as_view(),
        name="confirm_email",
    ),
    path(
        "password-reset/",
        views.PasswordResetRequestView.as_view(),
        name="password_reset",
    ),
    path(
        "password-reset/confirm/",
        views.PasswordResetConfirmView.as_view(),
        name="password_reset_confirm",
    ),
    path(
        "change-password/",
        views.ChangePasswordView.as_view(),
        name="change_password",
    ),
    path(
        "change-email/",
        views.EmailChangeRequestView.as_view(),
        name="change_email",
    ),
]
