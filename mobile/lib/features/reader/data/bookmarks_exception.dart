import 'package:dio/dio.dart';

class BookmarksException implements Exception {
  BookmarksException(this.message);

  final String message;

  factory BookmarksException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return BookmarksException(data['detail'] as String);
    }
    return BookmarksException('Не удалось обновить закладки. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
