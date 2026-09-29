import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/order.dart';
import '../order_date_format.dart';
import '../orders_providers.dart';
import 'order_detail_screen.dart';

/// Экран «Мои заказы» из ТЗ: список заказов (дата, сумма, статус),
/// от новых к старым — сортировку обеспечивает бэкенд. Пока без точки
/// входа из UI — она появится в «Профиль» на Phase 9, там же, где сам
/// экран профиля.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersTitle)),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.ordersLoadError),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(orderHistoryProvider),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (orders) => orders.isEmpty
            ? Center(child: Text(l10n.ordersEmpty))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _OrderTile(order: orders[index]),
              ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.orderTileTitle(order.id, order.itemCount)),
      subtitle: Text(
        '${formatOrderDate(order.createdAt, Localizations.localeOf(context).languageCode)} · '
        '${order.status.label(l10n)}',
      ),
      trailing: Text(
        '${order.totalAmount.toStringAsFixed(0)} ₽',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
    );
  }
}
