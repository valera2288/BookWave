from django.urls import path

from . import views

urlpatterns = [
    path("validate/", views.PromoValidateView.as_view(), name="promo_validate"),
    path("admin/", views.PromoCodeAdminListCreateView.as_view(), name="promo_admin_list"),
    path("admin/<int:pk>/", views.PromoCodeAdminDetailView.as_view(), name="promo_admin_detail"),
]
