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

  Future<OrderPage> fetchOrders() async {
    try {
      final response = await _dio.get('/orders/');
      return OrderPage.fromJson(response.data as Map<String, dynamic>);
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
