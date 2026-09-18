from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DeviceToken, NotificationPreference
from .serializers import (
    DeviceTokenSerializer,
    NotificationPreferenceItemSerializer,
    NotificationPreferenceUpdateSerializer,
)


class NotificationPreferenceListView(APIView):
    """Настройки push-категорий текущего пользователя (ТЗ: «включение и
    отключение push-уведомлений по категориям»). Категория без явно
    сохранённой записи считается включённой — см. `services._is_category_enabled`."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        saved = dict(
            NotificationPreference.objects.filter(user=request.user).values_list(
                "category", "enabled"
            )
        )
        data = [
            {"category": category, "label": label, "enabled": saved.get(category, True)}
            for category, label in NotificationPreference.Category.choices
        ]
        return Response(NotificationPreferenceItemSerializer(data, many=True).data)


class NotificationPreferenceUpdateView(APIView):
    """Переключение одной push-категории. Запись создаётся только теперь —
    до первого изменения категория просто считается включённой по умолчанию."""

    permission_classes = [IsAuthenticated]

    def patch(self, request, category):
        if category not in NotificationPreference.Category.values:
            return Response({"detail": "Неизвестная категория."}, status=status.HTTP_404_NOT_FOUND)

        serializer = NotificationPreferenceUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        pref, _ = NotificationPreference.objects.update_or_create(
            user=request.user,
            category=category,
            defaults={"enabled": serializer.validated_data["enabled"]},
        )
        return Response({"category": pref.category, "enabled": pref.enabled})


class DeviceTokenRegisterView(APIView):
    """Регистрация FCM-токена устройства. Токен уникален глобально — если
    он уже привязан к другому пользователю (переустановка приложения,
    смена аккаунта на одном устройстве), переносим его на текущего, а не
    падаем на конфликте уникальности."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token, _ = DeviceToken.objects.update_or_create(
            token=serializer.validated_data["token"],
            defaults={
                "user": request.user,
                "platform": serializer.validated_data["platform"],
            },
        )
        return Response(DeviceTokenSerializer(token).data, status=status.HTTP_201_CREATED)

    def delete(self, request):
        """Отвязка токена (логаут) — без этого устройство продолжало бы
        получать push для аккаунта, из которого уже вышли."""
        token = request.query_params.get("token")
        if not token:
            return Response({"detail": "Не передан token."}, status=status.HTTP_400_BAD_REQUEST)
        DeviceToken.objects.filter(user=request.user, token=token).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
