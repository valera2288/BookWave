import 'package:dio/dio.dart';

import '../storage/local_storage.dart';

/// Прикрепляет access-токен к защищённым запросам; при 401 один раз
/// пытается обновить его через refresh-токен и повторяет исходный запрос.
/// Публичные auth-эндпоинты (login/register/...) не трогает — иначе
/// протухший access-токен в заголовке ломал бы их (JWT-аутентификация DRF
/// отклоняет невалидный токен ещё до проверки permission_classes).
class AuthInterceptor extends Interceptor {
  // Private fields can't be initializing formals across library files
  // (this class is constructed from providers.dart), hence the body assignment.
  AuthInterceptor({required Dio dio, required SecureSessionStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureSessionStorage _storage;
  Future<String?>? _refreshing;

  static const _publicPaths = [
    '/users/register/',
    '/users/login/',
    '/users/token/refresh/',
    '/users/password-reset/',
    '/users/confirm-email/',
  ];

  bool _isPublic(String path) => _publicPaths.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await _storage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra['retried'] == true;
    if (err.response?.statusCode != 401 || _isPublic(request.path) || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      handler.next(err);
      return;
    }

    request.extra['retried'] = true;
    request.headers['Authorization'] = 'Bearer $newAccessToken';
    try {
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    // Несколько параллельных 401 не должны запускать несколько refresh —
    // переиспользуем один и тот же Future, пока он не завершится.
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null) return null;
    try {
      final response = await _dio.post(
        '/users/token/refresh/',
        data: {'refresh': refreshToken},
      );
      final newAccessToken = response.data['access'] as String;
      await _storage.saveTokens(accessToken: newAccessToken, refreshToken: refreshToken);
      return newAccessToken;
    } on DioException catch (e) {
      // Стираем токены, только если сервер отверг refresh-токен. Без ответа
      // (нет сети) сессия остаётся — повторим, когда связь появится.
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) await _storage.clear();
      return null;
    }
  }
}
