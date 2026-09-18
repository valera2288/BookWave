import 'package:dio/dio.dart';

class CatalogException implements Exception {
  CatalogException(this.message);

  final String message;

  factory CatalogException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return CatalogException(data['detail'] as String);
    }
    return CatalogException('Не удалось загрузить данные. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
