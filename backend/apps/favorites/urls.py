from django.urls import path

from . import views

urlpatterns = [
    path("", views.FavoriteListCreateView.as_view(), name="favorite_list_create"),
    path("<int:book_id>/", views.FavoriteDeleteView.as_view(), name="favorite_delete"),
]
