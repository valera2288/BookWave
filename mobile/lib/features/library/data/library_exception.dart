import 'package:dio/dio.dart';

class LibraryException implements Exception {
  LibraryException(this.message);

  final String message;

  factory LibraryException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return LibraryException(data['detail'] as String);
    }
    return LibraryException('Не удалось загрузить библиотеку. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
