import 'package:dio/dio.dart';

import '../domain/order.dart';
import 'orders_exception.dart';

class OrdersApi {
  OrdersApi(this._dio);

  final Dio _dio;

  Future<Order> checkout({required String cardNumber, String? promoCode}) async {
    try {
      final response = await _dio.post(
        '/orders/checkout/',
        data: {
          'card_number': cardNumber,
          if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrdersException.fromDioError(e);
    }
  }

  /// Бэкенд отдаёт историю постранично (по 20) — ТЗ требует список всех
  /// заказов, поэтому собираем все страницы.
  Future<OrderPage> fetchOrders() async {
    try {
      final orders = <OrderSummary>[];
      var page = 1;
      while (true) {
        final response = await _dio.get('/orders/', queryParameters: {'page': page});
        final data = response.data as Map<String, dynamic>;
        orders.addAll(OrderPage.fromJson(data).orders);
        if (data['next'] == null) break;
        page += 1;
      }
      return OrderPage(orders: orders);
    } on DioException catch (e) {
      throw OrdersException.fromDioError(e);
    }
  }

  Future<Order> fetchOrder(int id) async {
    try {
      final response = await _dio.get('/orders/$id/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrdersException.fromDioError(e);
    }
  }
}
