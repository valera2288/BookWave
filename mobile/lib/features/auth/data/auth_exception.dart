import 'package:dio/dio.dart';

import '../../../core/current_locale.dart';
import '../../../l10n/app_localizations.dart';

/// Человекочитаемая ошибка auth-запроса, извлечённая из ответа DRF
/// ({"detail": "..."} для общих ошибок или {"field": ["..."]} для валидации).
class AuthException implements Exception {
  AuthException(this.message, {this.retryAfter, this.field, this.statusCode});

  final String message;
  final int? retryAfter;

  /// HTTP-статус ответа; `null` — ответа не было (нет сети/сервер недоступен).
  final int? statusCode;

  /// Имя поля сериализатора, к которому относится ошибка (например,
  /// "password"), если DRF вернул её в виде `{"поле": ["..."]}`. Нужно,
  /// чтобы показать ошибку прямо под нужным полем формы, а не только
  /// снекбаром, который легко пропустить.
  final String? field;

  factory AuthException.fromDioError(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) {
        return AuthException(
          detail,
          retryAfter: data['retry_after'] as int?,
          statusCode: statusCode,
        );
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty && value.first is String) {
          return AuthException(
            value.first as String,
            field: entry.key as String?,
            statusCode: statusCode,
          );
        }
      }
    }
    return AuthException(
      lookupAppLocalizations(currentAppLocale).exceptionAuthGeneric,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
