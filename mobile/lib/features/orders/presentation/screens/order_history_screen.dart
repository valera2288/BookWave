import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить заказы'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(orderHistoryProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('Заказов пока нет'))
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Заказ #${order.id} · ${order.itemCount} книг(и)'),
      subtitle: Text('${formatOrderDate(order.createdAt)} · ${order.status.label}'),
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
