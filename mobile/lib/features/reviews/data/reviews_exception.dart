import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

class ReviewsException implements Exception {
  ReviewsException(this.message);

  final String message;

  factory ReviewsException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ReviewsException(data['detail'] as String);
    }
    return ReviewsException(lookupAppLocalizations(currentAppLocale).exceptionReviewsGeneric);
  }

  @override
  String toString() => message;
}
