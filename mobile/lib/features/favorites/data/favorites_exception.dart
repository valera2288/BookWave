import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class FavoritesException implements Exception {
  FavoritesException(this.message);

  final String message;

  factory FavoritesException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return FavoritesException(data['detail'] as String);
    }
    return FavoritesException(lookupAppLocalizations(currentAppLocale).exceptionFavoritesGeneric);
  }

  @override
  String toString() => message;
}
