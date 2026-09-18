import 'package:dio/dio.dart';

class FavoritesException implements Exception {
  FavoritesException(this.message);

  final String message;

  factory FavoritesException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return FavoritesException(data['detail'] as String);
    }
    return FavoritesException('Не удалось обновить избранное. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
