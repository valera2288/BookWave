from decimal import Decimal

from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.cart.services import get_cart
from apps.users.permissions import IsAdminRole

from .models import PromoCode
from .serializers import PromoCodeAdminSerializer, PromoValidateSerializer
from .services import PromoError, validate_promo


class PromoValidateView(APIView):
    """Превью применения промокода на экране корзины (ТЗ: «скидка немедленно
    применяется к итоговой сумме корзины с визуальным отображением суммы
    экономии»). Ничего не сохраняет — checkout проверяет промокод заново."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PromoValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        cart = get_cart(request.user)
        subtotal = sum((item.book.price for item in cart.items.all()), Decimal("0"))

        try:
            _, discount = validate_promo(serializer.validated_data["code"], subtotal)
        except PromoError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return Response({"subtotal": subtotal, "discount": discount, "total": subtotal - discount})


class PromoCodeAdminListCreateView(generics.ListCreateAPIView):
    """Промокоды в админ-панели: список со статусом активен/истёк/исчерпан
    и создание новых (ТЗ)."""

    serializer_class = PromoCodeAdminSerializer
    permission_classes = [IsAdminRole]
    pagination_class = None
    queryset = PromoCode.objects.order_by("-valid_from")


class PromoCodeAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = PromoCodeAdminSerializer
    permission_classes = [IsAdminRole]
    queryset = PromoCode.objects.all()
