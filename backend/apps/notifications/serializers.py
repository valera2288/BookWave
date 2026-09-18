from rest_framework import serializers

from .models import DeviceToken


class NotificationPreferenceItemSerializer(serializers.Serializer):
    """Один пункт списка настроек (ТЗ, экран «Настройки»: push-категории)."""

    category = serializers.CharField()
    label = serializers.CharField()
    enabled = serializers.BooleanField()


class NotificationPreferenceUpdateSerializer(serializers.Serializer):
    enabled = serializers.BooleanField()


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ["token", "platform"]
        # `unique=True` на модели заставляет DRF молча добавить сюда
        # `UniqueValidator` — он бы отклонял повторную регистрацию уже
        # известного токена до того, как отработает `update_or_create` в
        # `DeviceTokenRegisterView` (перенос токена на нового владельца —
        # намеренное поведение, не ошибка).
        extra_kwargs = {"token": {"validators": []}}
