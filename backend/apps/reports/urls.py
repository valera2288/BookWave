from django.urls import path

from . import views

urlpatterns = [
    path("sales/", views.SalesReportView.as_view(), name="sales_report"),
    path("sales/export/", views.SalesReportExportView.as_view(), name="sales_report_export"),
]
