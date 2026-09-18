import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/order.dart';
import '../order_date_format.dart';
import '../orders_providers.dart';

/// Детальный экран заказа из ТЗ: список купленных книг, их количеством
/// (общее число позиций в заказе — у книг нет отдельного поля
/// «количество», повторная покупка одной и той же книги не создаёт
/// вторую позицию) и стоимостью.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Заказ #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить заказ'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(order.status.label, style: theme.textTheme.titleMedium),
        Text(
          formatOrderDate(order.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          '${order.items.length} книг(и)',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Divider(height: 32),
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(item.book.title, overflow: TextOverflow.ellipsis)),
                Text('${item.priceAtPurchase.toStringAsFixed(0)} ₽'),
              ],
            ),
          ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого', style: theme.textTheme.titleMedium),
            Text(
              '${order.totalAmount.toStringAsFixed(0)} ₽',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
