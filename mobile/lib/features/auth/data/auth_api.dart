import 'dart:io';

import 'package:dio/dio.dart';

import 'auth_exception.dart';

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Тонкая обёртка над `/api/users/*` — без состояния, без кеша токенов
/// (это забота `AuthRepository`).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<(AuthTokens, Map<String, dynamic>)> register({
    required String email,
    required String name,
    required String password,
    required bool acceptTerms,
  }) async {
    try {
      final response = await _dio.post('/users/register/', data: {
        'email': email,
        'name': name,
        'password': password,
        'accept_terms': acceptTerms,
      });
      final data = response.data as Map<String, dynamic>;
      return (
        AuthTokens(
          access: data['access'] as String,
          refresh: data['refresh'] as String,
        ),
        data['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<AuthTokens> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/users/login/', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      return AuthTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get('/users/me/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/users/password-reset/', data: {'email': email});
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    try {
      await _dio.post('/users/password-reset/confirm/', data: {
        'token': token,
        'new_password': newPassword,
        'new_password2': newPassword2,
      });
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<void> confirmEmail(String token) async {
    try {
      await _dio.post('/users/confirm-email/$token/');
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  /// `avatarFile` есть только когда пользователь выбрал новое фото —
  /// тогда запрос уходит как multipart, иначе обычным JSON (остальные
  /// поля необязательны, PATCH частичный).
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? theme,
    String? language,
    File? avatarFile,
  }) async {
    try {
      final data = avatarFile == null
          ? <String, dynamic>{
              'name': ?name,
              'theme': ?theme,
              'language': ?language,
            }
          : FormData.fromMap({
              'name': ?name,
              'theme': ?theme,
              'language': ?language,
              'avatar': await MultipartFile.fromFile(avatarFile.path),
            });
      final response = await _dio.patch('/users/me/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<void> requestEmailChange(String newEmail) async {
    try {
      await _dio.post('/users/change-email/', data: {'new_email': newEmail});
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }

  Future<AuthTokens> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    try {
      final response = await _dio.post('/users/change-password/', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password2': newPassword2,
      });
      final data = response.data as Map<String, dynamic>;
      return AuthTokens(access: data['access'] as String, refresh: data['refresh'] as String);
    } on DioException catch (e) {
      throw AuthException.fromDioError(e);
    }
  }
}
