from django.db.models import Prefetch

from apps.catalog.models import Book
from apps.catalog.services import annotate_ratings

from .models import Cart, CartItem


def get_cart(user):
    """Корзина пользователя с аннотированными рейтингами позиций
    (создаётся лениво — отдельного экрана/шага регистрации корзины нет).
    Позиции с мягко удалённой книгой не показываем и не считаем в total —
    книга могла исчезнуть из каталога уже после добавления в корзину."""
    cart, _ = Cart.objects.get_or_create(user=user)
    annotated_books = annotate_ratings(Book.objects.all()).prefetch_related("authors")
    active_items = CartItem.objects.filter(book__is_active=True).prefetch_related(
        Prefetch("book", queryset=annotated_books)
    )
    return (
        Cart.objects.filter(id=cart.id)
        .prefetch_related(Prefetch("items", queryset=active_items))
        .get()
    )
