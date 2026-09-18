from django.urls import path

from . import views

urlpatterns = [
    path("", views.ActiveBannerListView.as_view(), name="banner_list"),
]
