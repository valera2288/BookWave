from rest_framework import serializers


class TopBookSerializer(serializers.Serializer):
    book_id = serializers.IntegerField()
    title = serializers.CharField()
    quantity_sold = serializers.IntegerField()
    revenue = serializers.DecimalField(max_digits=12, decimal_places=2)


class SalesReportSerializer(serializers.Serializer):
    period = serializers.CharField()
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    order_count = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    top_books = TopBookSerializer(many=True)
