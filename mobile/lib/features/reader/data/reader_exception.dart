import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class ReaderException implements Exception {
  ReaderException(this.message);

  final String message;

  factory ReaderException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ReaderException(data['detail'] as String);
    }
    return ReaderException(lookupAppLocalizations(currentAppLocale).exceptionReaderGeneric);
  }

  @override
  String toString() => message;
}
