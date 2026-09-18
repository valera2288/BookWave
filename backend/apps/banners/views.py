from django.db.models import Q
from django.utils import timezone
from rest_framework import generics
from rest_framework.permissions import AllowAny

from .models import Banner
from .serializers import BannerSerializer


class ActiveBannerListView(generics.ListAPIView):
    """Карусель баннеров на главной. Управляются через Django-админку
    (см. ARCHITECTURE.md) — здесь только публичное чтение активных."""

    serializer_class = BannerSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        now = timezone.now()
        return (
            Banner.objects.filter(is_active=True)
            .filter(Q(starts_at__isnull=True) | Q(starts_at__lte=now))
            .filter(Q(ends_at__isnull=True) | Q(ends_at__gte=now))
            .order_by("position")
        )
