import 'package:dio/dio.dart';

/// Человекочитаемая ошибка auth-запроса, извлечённая из ответа DRF
/// ({"detail": "..."} для общих ошибок или {"field": ["..."]} для валидации).
class AuthException implements Exception {
  AuthException(this.message, {this.retryAfter, this.field});

  final String message;
  final int? retryAfter;

  /// Имя поля сериализатора, к которому относится ошибка (например,
  /// "password"), если DRF вернул её в виде `{"поле": ["..."]}`. Нужно,
  /// чтобы показать ошибку прямо под нужным полем формы, а не только
  /// снекбаром, который легко пропустить.
  final String? field;

  factory AuthException.fromDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) {
        return AuthException(detail, retryAfter: data['retry_after'] as int?);
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty && value.first is String) {
          return AuthException(value.first as String, field: entry.key as String?);
        }
      }
    }
    return AuthException('Не удалось выполнить запрос. Проверьте соединение.');
  }

  @override
  String toString() => message;
}
