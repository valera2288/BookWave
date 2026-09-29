import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class CartException implements Exception {
  CartException(this.message);

  final String message;

  factory CartException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return CartException(data['detail'] as String);
    }
    return CartException(lookupAppLocalizations(currentAppLocale).exceptionCartGeneric);
  }

  @override
  String toString() => message;
}
