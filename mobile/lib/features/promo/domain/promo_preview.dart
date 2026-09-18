/// Результат превью применения промокода к текущей корзине (ТЗ: «скидка
/// немедленно применяется... с визуальным отображением суммы экономии»).
/// Ничего не сохраняется на сервере — реальная проверка происходит заново
/// при оформлении заказа.
class PromoPreview {
  const PromoPreview({
    required this.code,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final String code;
  final double subtotal;
  final double discount;
  final double total;

  factory PromoPreview.fromJson(String code, Map<String, dynamic> json) => PromoPreview(
        code: code,
        subtotal: double.parse(json['subtotal'].toString()),
        discount: double.parse(json['discount'].toString()),
        total: double.parse(json['total'].toString()),
      );
}
