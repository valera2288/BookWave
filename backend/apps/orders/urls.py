from django.urls import path

from . import views

urlpatterns = [
    path("checkout/", views.CheckoutView.as_view(), name="checkout"),
    path("admin/", views.OrderAdminListView.as_view(), name="order_admin_list"),
    path("admin/export/", views.OrderAdminExportView.as_view(), name="order_admin_export"),
    path("admin/<int:pk>/", views.OrderAdminDetailView.as_view(), name="order_admin_detail"),
    path("", views.OrderListView.as_view(), name="order_list"),
    path("<int:pk>/", views.OrderDetailView.as_view(), name="order_detail"),
]
