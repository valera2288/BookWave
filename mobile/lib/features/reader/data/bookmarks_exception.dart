import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class BookmarksException implements Exception {
  BookmarksException(this.message);

  final String message;

  factory BookmarksException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return BookmarksException(data['detail'] as String);
    }
    return BookmarksException(lookupAppLocalizations(currentAppLocale).exceptionBookmarksGeneric);
  }

  @override
  String toString() => message;
}
