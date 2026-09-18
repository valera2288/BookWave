from django.urls import path

from . import views

urlpatterns = [
    path("", views.CartDetailView.as_view(), name="cart_detail"),
    path("items/", views.CartItemCreateView.as_view(), name="cart_item_create"),
    path("items/<int:book_id>/", views.CartItemDeleteView.as_view(), name="cart_item_delete"),
]
