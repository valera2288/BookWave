from datetime import timedelta
from decimal import Decimal

from django.db.models import Count, Sum
from django.utils import timezone
from django.utils.dateparse import parse_date

from apps.orders.models import Order, OrderItem

TOP_BOOKS_LIMIT = 10
PERIOD_CHOICES = {"day", "week", "month", "custom"}


class ReportError(Exception):
    """Некорректные параметры запроса отчёта (400, не 500)."""


def _resolve_period(period, date_from_param, date_to_param):
    if period not in PERIOD_CHOICES:
        raise ReportError("Период должен быть одним из: day, week, month, custom.")

    today = timezone.localdate()
    if period == "day":
        return today, today
    if period == "week":
        return today - timedelta(days=today.weekday()), today
    if period == "month":
        return today.replace(day=1), today

    date_from = parse_date(date_from_param or "")
    date_to = parse_date(date_to_param or "")
    if not date_from or not date_to or date_from > date_to:
        raise ReportError("Укажите корректный диапазон: date_from и date_to (date_from <= date_to).")
    return date_from, date_to


def build_sales_report(period, date_from_param=None, date_to_param=None):
    """Отчёт о продажах за период (ТЗ): количество заказов, общая выручка,
    топ-10 продаваемых книг. Учитываются только оплаченные заказы —
    отменённые и возвраты не считаются продажами."""
    date_from, date_to = _resolve_period(period, date_from_param, date_to_param)

    orders = Order.objects.filter(
        status=Order.Status.PAID,
        created_at__date__gte=date_from,
        created_at__date__lte=date_to,
    )
    order_count = orders.count()
    total_revenue = orders.aggregate(total=Sum("total_amount"))["total"] or Decimal("0")

    top_books = list(
        OrderItem.objects.filter(order__in=orders)
        .values("book_id", "book__title")
        .annotate(quantity_sold=Count("id"), revenue=Sum("price_at_purchase"))
        .order_by("-quantity_sold")[:TOP_BOOKS_LIMIT]
    )

    return {
        "period": period,
        "date_from": date_from,
        "date_to": date_to,
        "order_count": order_count,
        "total_revenue": total_revenue,
        "top_books": [
            {
                "book_id": row["book_id"],
                "title": row["book__title"],
                "quantity_sold": row["quantity_sold"],
                "revenue": row["revenue"],
            }
            for row in top_books
        ],
    }
