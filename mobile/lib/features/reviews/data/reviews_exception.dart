import 'package:dio/dio.dart';

class ReviewsException implements Exception {
  ReviewsException(this.message);

  final String message;

  factory ReviewsException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ReviewsException(data['detail'] as String);
    }
    return ReviewsException('Не удалось обновить отзыв. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
