import '../../../l10n/app_localizations.dart';
import '../../catalog/domain/book_summary.dart';

/// Значения соответствуют `Order.Status` в `apps/orders/models.py`.
enum OrderStatus {
  paid('paid'),
  cancelled('cancelled'),
  refunded('refunded');

  const OrderStatus(this.apiValue);

  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
        OrderStatus.paid => l10n.orderStatusPaid,
        OrderStatus.cancelled => l10n.orderStatusCancelled,
        OrderStatus.refunded => l10n.orderStatusRefunded,
      };

  factory OrderStatus.fromApiValue(String value) => OrderStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => OrderStatus.paid,
      );
}

class OrderItemEntry {
  const OrderItemEntry({required this.id, required this.book, required this.priceAtPurchase});

  final int id;
  final BookSummary book;
  final double priceAtPurchase;

  factory OrderItemEntry.fromJson(Map<String, dynamic> json) => OrderItemEntry(
        id: json['id'] as int,
        book: BookSummary.fromJson(json['book'] as Map<String, dynamic>),
        priceAtPurchase: double.parse(json['price_at_purchase'].toString()),
      );
}

/// Заказ целиком — то, что отдаёт `OrderDetailSerializer` (детальный экран
/// и ответ checkout).
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItemEntry> items;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        status: OrderStatus.fromApiValue(json['status'] as String),
        totalAmount: double.parse(json['total_amount'].toString()),
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['items'] as List)
            .map((e) => OrderItemEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Строка истории заказов — то, что отдаёт `OrderListSerializer` (без
/// состава, только сводка).
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.createdAt,
  });

  final int id;
  final OrderStatus status;
  final double totalAmount;
  final int itemCount;
  final DateTime createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: json['id'] as int,
        status: OrderStatus.fromApiValue(json['status'] as String),
        totalAmount: double.parse(json['total_amount'].toString()),
        itemCount: json['item_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class OrderPage {
  const OrderPage({required this.orders});

  final List<OrderSummary> orders;

  factory OrderPage.fromJson(Map<String, dynamic> json) => OrderPage(
        orders: (json['results'] as List)
            .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
