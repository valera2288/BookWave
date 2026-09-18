import 'package:dio/dio.dart';

class CartException implements Exception {
  CartException(this.message);

  final String message;

  factory CartException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return CartException(data['detail'] as String);
    }
    return CartException('Не удалось обновить корзину. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
