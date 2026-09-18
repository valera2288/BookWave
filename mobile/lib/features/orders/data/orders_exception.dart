import 'package:dio/dio.dart';

class OrdersException implements Exception {
  OrdersException(this.message);

  final String message;

  factory OrdersException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return OrdersException(data['detail'] as String);
    }
    return OrdersException('Не удалось оформить заказ. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
