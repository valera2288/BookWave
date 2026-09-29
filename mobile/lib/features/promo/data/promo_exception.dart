import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class PromoException implements Exception {
  PromoException(this.message);

  final String message;

  factory PromoException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return PromoException(data['detail'] as String);
    }
    return PromoException(lookupAppLocalizations(currentAppLocale).exceptionPromoGeneric);
  }

  @override
  String toString() => message;
}
