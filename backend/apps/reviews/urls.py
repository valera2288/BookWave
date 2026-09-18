from django.urls import path

from . import views

urlpatterns = [
    path("book/<int:book_id>/", views.ReviewListView.as_view(), name="review_list"),
    path("book/<int:book_id>/mine/", views.MyReviewView.as_view(), name="review_mine"),
    path("admin/", views.ReviewAdminListView.as_view(), name="review_admin_list"),
    path("admin/<int:pk>/", views.ReviewAdminDetailView.as_view(), name="review_admin_detail"),
]
