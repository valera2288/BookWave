import 'package:dio/dio.dart';

import '../domain/notification_preference.dart';
import 'notifications_exception.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  /// Регистрирует токен устройства для push (ТЗ, категория «новинки» и
  /// т.д.) — вызывается после входа/восстановления сессии.
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    try {
      await _dio.post(
        '/notifications/device-tokens/',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw NotificationsException.fromDioError(e);
    }
  }

  /// Отвязывает токен устройства при выходе из аккаунта — без этого
  /// устройство продолжало бы получать push для уже вышедшего пользователя.
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dio.delete('/notifications/device-tokens/', queryParameters: {'token': token});
    } on DioException catch (e) {
      throw NotificationsException.fromDioError(e);
    }
  }

  /// Настройки push-категорий (ТЗ, экран «Настройки»: «включение и
  /// отключение push-уведомлений по категориям»).
  Future<List<NotificationPreference>> fetchPreferences() async {
    try {
      final response = await _dio.get('/notifications/preferences/');
      return (response.data as List)
          .map((e) => NotificationPreference.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NotificationsException.fromDioError(e);
    }
  }

  Future<void> updatePreference({required String category, required bool enabled}) async {
    try {
      await _dio.patch('/notifications/preferences/$category/', data: {'enabled': enabled});
    } on DioException catch (e) {
      throw NotificationsException.fromDioError(e);
    }
  }
}
