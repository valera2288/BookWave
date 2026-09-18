from django.core.cache import cache
from rest_framework import generics, status
from rest_framework.exceptions import APIException
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import User
from .serializers import (
    BookWaveTokenObtainPairSerializer,
    ChangePasswordSerializer,
    EmailChangeRequestSerializer,
    EmailConfirmationSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UpdateProfileSerializer,
    UserSerializer,
)
from .services import (
    send_email_change_confirmation,
    send_email_confirmation,
    send_password_reset_email,
)

LOGIN_ATTEMPT_LIMIT = 3
LOGIN_LOCKOUT_SECONDS = 60

PASSWORD_RESET_REQUEST_LIMIT = 3
PASSWORD_RESET_REQUEST_WINDOW_SECONDS = 3600


def _increment_attempts(cache_key: str, timeout: int) -> int:
    """Атомарно увеличивает счётчик попыток в cache.

    cache.add() выставляет счётчик только если ключа ещё нет (атомарно),
    cache.incr() атомарно увеличивает существующий — в отличие от пары
    get()+set(), это не теряет попытки при параллельных запросах.
    """
    cache.add(cache_key, 0, timeout=timeout)
    return cache.incr(cache_key)


class MeView(APIView):
    """GET — текущий профиль; PATCH — редактирование (имя/аватар/тема/язык,
    тот же GET+PATCH-в-одном-APIView паттерн, что и `LibraryDetailView`).
    E-mail сюда не входит — у него отдельный флоу с реконфирмацией
    (`EmailChangeRequestView`)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user, context={"request": request}).data)

    def patch(self, request):
        serializer = UpdateProfileSerializer(
            instance=request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user, context={"request": request}).data)


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        send_email_confirmation(user)
        token = BookWaveTokenObtainPairSerializer.get_token(user)
        return Response(
            {
                "user": UserSerializer(user, context={"request": request}).data,
                "access": str(token.access_token),
                "refresh": str(token),
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    serializer_class = BookWaveTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        email = (request.data.get("email") or "").strip().lower()
        cache_key = f"login_attempts:{email}"
        if cache.get(cache_key, 0) >= LOGIN_ATTEMPT_LIMIT:
            return Response(
                {
                    "detail": "Слишком много неудачных попыток входа. Повторите через 60 секунд.",
                    "retry_after": LOGIN_LOCKOUT_SECONDS,
                },
                status=status.HTTP_423_LOCKED,
            )

        # Неверные креды и невалидный ввод приходят как исключение
        # (AuthenticationFailed/ValidationError), а не как response с
        # status_code != 200 — ловим его, чтобы засчитать попытку и
        # пробросить дальше исходную ошибку без изменений.
        try:
            response = super().post(request, *args, **kwargs)
        except APIException:
            _increment_attempts(cache_key, LOGIN_LOCKOUT_SECONDS)
            raise

        cache.delete(cache_key)
        return response


class ConfirmEmailView(APIView):
    permission_classes = [AllowAny]

    # GET — переход по ссылке из письма (браузер делает GET, не POST);
    # POST оставлен для мобильного клиента, если понадобится подтверждать
    # e-mail прямо из приложения, а не по ссылке.
    def get(self, request, token):
        return self._confirm(token)

    def post(self, request, token):
        return self._confirm(token)

    def _confirm(self, token):
        serializer = EmailConfirmationSerializer(data={"token": token})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "E-mail подтверждён."})


class EmailChangeRequestView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = EmailChangeRequestSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        send_email_change_confirmation(request.user, serializer.validated_data["new_email"])
        return Response({"detail": "Письмо с подтверждением отправлено на новый адрес."})


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].strip().lower()

        cache_key = f"password_reset_attempts:{email}"
        if cache.get(cache_key, 0) >= PASSWORD_RESET_REQUEST_LIMIT:
            return Response(
                {
                    "detail": "Слишком много запросов на сброс пароля для этого e-mail. Повторите позже.",
                    "retry_after": PASSWORD_RESET_REQUEST_WINDOW_SECONDS,
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        _increment_attempts(cache_key, PASSWORD_RESET_REQUEST_WINDOW_SECONDS)

        user = User.objects.filter(email=email).first()
        if user:
            send_password_reset_email(user)
        return Response({"detail": "Если e-mail зарегистрирован, письмо отправлено."})


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"detail": "Пароль изменён."})


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # `token_version` инкрементируется глобально (см. serializer.save()),
        # поэтому и токены ЭТОГО запроса становятся недействительны для
        # последующих запросов — ТЗ требует завершать только "прочие"
        # сессии, значит текущему устройству нужна свежая пара, иначе оно
        # тоже вылетит из аккаунта тем же способом, что и остальные.
        token = BookWaveTokenObtainPairSerializer.get_token(user)
        return Response(
            {
                "detail": "Пароль изменён. Остальные сессии завершены.",
                "access": str(token.access_token),
                "refresh": str(token),
            }
        )
