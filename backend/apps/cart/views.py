from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.library.models import LibraryEntry

from .models import Cart, CartItem
from .serializers import CartItemCreateSerializer, CartSerializer
from .services import get_cart


class CartDetailView(generics.RetrieveAPIView):
    serializer_class = CartSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return get_cart(self.request.user)


class CartItemCreateView(APIView):
    """Добавление книги в корзину (ТЗ: повторное добавление уже имеющейся
    в корзине книги не создаёт дубликат). Книгу, уже купленную (есть в
    библиотеке), добавить нельзя — иначе checkout списал бы деньги за то,
    чем пользователь уже владеет."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CartItemCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        book = serializer.validated_data["book"]

        if LibraryEntry.objects.filter(user=request.user, book=book).exists():
            return Response(
                {"detail": "Эта книга уже в вашей библиотеке."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cart, _ = Cart.objects.get_or_create(user=request.user)
        _, created = CartItem.objects.get_or_create(cart=cart, book=book)
        return Response(
            CartSerializer(get_cart(request.user)).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class CartItemDeleteView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        cart, _ = Cart.objects.get_or_create(user=self.request.user)
        return get_object_or_404(CartItem, cart=cart, book_id=self.kwargs["book_id"])
