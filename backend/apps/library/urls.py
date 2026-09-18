from django.urls import path

from . import views

urlpatterns = [
    path("", views.LibraryListView.as_view(), name="library_list"),
    path("<int:book_id>/", views.LibraryDetailView.as_view(), name="library_detail"),
]
