from django.urls import path

from . import views

urlpatterns = [
    path("", views.BookmarkListCreateView.as_view(), name="bookmark_list_create"),
    path("<int:pk>/", views.BookmarkDeleteView.as_view(), name="bookmark_delete"),
]
