import 'package:dio/dio.dart';

class NotificationsException implements Exception {
  NotificationsException(this.message);

  final String message;

  factory NotificationsException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return NotificationsException(data['detail'] as String);
    }
    return NotificationsException('Не удалось обновить настройки уведомлений.');
  }

  @override
  String toString() => message;
}
