import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class LibraryException implements Exception {
  LibraryException(this.message);

  final String message;

  factory LibraryException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return LibraryException(data['detail'] as String);
    }
    return LibraryException(lookupAppLocalizations(currentAppLocale).exceptionLibraryGeneric);
  }

  @override
  String toString() => message;
}
