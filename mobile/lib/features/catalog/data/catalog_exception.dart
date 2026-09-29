import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class CatalogException implements Exception {
  CatalogException(this.message);

  final String message;

  factory CatalogException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return CatalogException(data['detail'] as String);
    }
    return CatalogException(lookupAppLocalizations(currentAppLocale).exceptionCatalogGeneric);
  }

  @override
  String toString() => message;
}
