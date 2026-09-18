import 'package:dio/dio.dart';

class ReaderException implements Exception {
  ReaderException(this.message);

  final String message;

  factory ReaderException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ReaderException(data['detail'] as String);
    }
    return ReaderException('Не удалось загрузить файл книги. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
