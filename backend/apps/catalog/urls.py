from django.urls import path

from . import views

urlpatterns = [
    path("books/", views.BookListView.as_view(), name="book_list"),
    path("books/<int:pk>/", views.BookDetailView.as_view(), name="book_detail"),
    path("genres/", views.GenreListView.as_view(), name="genre_list"),
    path("authors/", views.AuthorListView.as_view(), name="author_list"),
    path("languages/", views.LanguageListView.as_view(), name="language_list"),
    path("recommendations/", views.RecommendationsView.as_view(), name="recommendations"),
    path("top-sellers/", views.TopSellersView.as_view(), name="top_sellers"),
    path(
        "admin/books/",
        views.BookAdminListCreateView.as_view(),
        name="admin_book_list_create",
    ),
    path(
        "admin/books/<int:pk>/",
        views.BookAdminDetailView.as_view(),
        name="admin_book_detail",
    ),
    path(
        "admin/genres/",
        views.GenreAdminListCreateView.as_view(),
        name="admin_genre_list_create",
    ),
    path(
        "admin/genres/<int:pk>/",
        views.GenreAdminDetailView.as_view(),
        name="admin_genre_detail",
    ),
    path(
        "admin/authors/",
        views.AuthorAdminListCreateView.as_view(),
        name="admin_author_list_create",
    ),
    path(
        "admin/authors/<int:pk>/",
        views.AuthorAdminDetailView.as_view(),
        name="admin_author_detail",
    ),
]
