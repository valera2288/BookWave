import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class OrdersException implements Exception {
  OrdersException(this.message);

  final String message;

  factory OrdersException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return OrdersException(data['detail'] as String);
    }
    return OrdersException(lookupAppLocalizations(currentAppLocale).exceptionOrdersGeneric);
  }

  @override
  String toString() => message;
}
