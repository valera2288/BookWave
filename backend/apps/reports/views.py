from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.users.permissions import IsAdminRole

from .export import export_csv, export_xlsx
from .serializers import SalesReportSerializer
from .services import ReportError, build_sales_report

EXPORT_FORMATS = {"xlsx", "csv"}


class SalesReportView(APIView):
    """Отчёт о продажах за период (ТЗ): количество заказов, общая выручка,
    топ-10 книг. `period` — day/week/month/custom; для custom обязательны
    date_from и date_to."""

    permission_classes = [IsAdminRole]

    def get(self, request):
        try:
            report = build_sales_report(
                request.query_params.get("period", "day"),
                request.query_params.get("date_from"),
                request.query_params.get("date_to"),
            )
        except ReportError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(SalesReportSerializer(report).data)


class SalesReportExportView(APIView):
    """Тот же отчёт, выгруженный в .xlsx или .csv (ТЗ).

    Параметр называется `file_format`, а не `format` — «format» уже занят
    встроенным DRF-механизмом выбора рендерера (`?format=json`); значение
    вроде «xlsx» под этим именем не проходит content negotiation вообще
    (падает в `Http404` до вызова `get()`), а не как невалидный формат."""

    permission_classes = [IsAdminRole]

    def get(self, request):
        export_format = request.query_params.get("file_format", "xlsx")
        if export_format not in EXPORT_FORMATS:
            return Response(
                {"detail": "Параметр file_format должен быть xlsx или csv."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            report = build_sales_report(
                request.query_params.get("period", "day"),
                request.query_params.get("date_from"),
                request.query_params.get("date_to"),
            )
        except ReportError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        return export_xlsx(report) if export_format == "xlsx" else export_csv(report)
