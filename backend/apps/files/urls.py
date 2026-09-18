from django.urls import path

from . import views

urlpatterns = [
    path(
        "books/<int:book_id>/<str:file_format>/",
        views.BookFileView.as_view(),
        name="book_file",
    ),
]
