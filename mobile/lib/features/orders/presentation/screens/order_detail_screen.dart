import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailTitle(orderId))),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.orderDetailLoadError),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: Text(l10n.commonRetry),
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
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(order.status.label(l10n), style: theme.textTheme.titleMedium),
        Text(
          formatOrderDate(order.createdAt, Localizations.localeOf(context).languageCode),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          l10n.orderItemCount(order.items.length),
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
            Text(l10n.cartTotal, style: theme.textTheme.titleMedium),
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
