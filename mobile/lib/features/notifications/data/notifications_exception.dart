import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsException implements Exception {
  NotificationsException(this.message);

  final String message;

  factory NotificationsException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return NotificationsException(data['detail'] as String);
    }
    return NotificationsException(
      lookupAppLocalizations(currentAppLocale).exceptionNotificationsGeneric,
    );
  }

  @override
  String toString() => message;
}
