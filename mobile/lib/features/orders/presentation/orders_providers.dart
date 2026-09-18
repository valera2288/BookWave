import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/order.dart';

final orderHistoryProvider = FutureProvider<List<OrderSummary>>(
  (ref) async => (await ref.watch(ordersApiProvider).fetchOrders()).orders,
);

final orderDetailProvider = FutureProvider.family<Order, int>(
  (ref, orderId) => ref.watch(ordersApiProvider).fetchOrder(orderId),
);
