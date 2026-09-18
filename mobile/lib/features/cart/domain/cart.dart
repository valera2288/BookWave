import '../../catalog/domain/book_summary.dart';

/// Позиция корзины — то, что отдаёт `CartItemSerializer`.
class CartItemEntry {
  const CartItemEntry({required this.id, required this.book, required this.addedAt});

  final int id;
  final BookSummary book;
  final DateTime addedAt;

  factory CartItemEntry.fromJson(Map<String, dynamic> json) => CartItemEntry(
        id: json['id'] as int,
        book: BookSummary.fromJson(json['book'] as Map<String, dynamic>),
        addedAt: DateTime.parse(json['added_at'] as String),
      );
}

/// Корзина целиком — то, что отдаёт `CartSerializer`. Скидка по промокоду
/// сюда не входит — она появится вместе с Phase 5 (checkout).
class Cart {
  const Cart({required this.items, required this.total});

  final List<CartItemEntry> items;
  final double total;

  static const empty = Cart(items: [], total: 0);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: (json['items'] as List)
            .map((e) => CartItemEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: double.parse(json['total'].toString()),
      );
}
