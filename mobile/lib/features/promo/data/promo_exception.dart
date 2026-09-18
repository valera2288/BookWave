import 'package:dio/dio.dart';

class PromoException implements Exception {
  PromoException(this.message);

  final String message;

  factory PromoException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return PromoException(data['detail'] as String);
    }
    return PromoException('Не удалось проверить промокод. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
