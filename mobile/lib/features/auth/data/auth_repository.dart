import 'dart:io';

import '../../../core/storage/local_storage.dart';
import '../domain/app_user.dart';
import 'auth_api.dart';

/// Связывает `AuthApi` (сеть) и `SecureSessionStorage` (токены на диске).
class AuthRepository {
  // Private fields can't be initializing formals across library files
  // (this class is constructed from providers.dart), hence the body assignment.
  AuthRepository({required AuthApi api, required SecureSessionStorage storage})
      : _api = api,
        _storage = storage;

  final AuthApi _api;
  final SecureSessionStorage _storage;

  /// Если в защищённом хранилище есть access-токен, считаем, что сессия
  /// была активна, и подгружаем профиль. Сам access-токен, если истёк,
  /// обновит `AuthInterceptor` на первом же запросе.
  Future<AppUser?> restoreSession() async {
    final accessToken = await _storage.accessToken;
    if (accessToken == null) return null;
    final data = await _api.me();
    return AppUser.fromJson(data);
  }

  Future<AppUser> register({
    required String email,
    required String name,
    required String password,
    required bool acceptTerms,
  }) async {
    final (tokens, userJson) = await _api.register(
      email: email,
      name: name,
      password: password,
      acceptTerms: acceptTerms,
    );
    await _storage.saveTokens(accessToken: tokens.access, refreshToken: tokens.refresh);
    return AppUser.fromJson(userJson);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final tokens = await _api.login(email: email, password: password);
    await _storage.saveTokens(accessToken: tokens.access, refreshToken: tokens.refresh);
    final data = await _api.me();
    return AppUser.fromJson(data);
  }

  Future<void> logout() => _storage.clear();

  Future<void> requestPasswordReset(String email) => _api.requestPasswordReset(email);

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) =>
      _api.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
        newPassword2: newPassword2,
      );

  Future<void> confirmEmail(String token) => _api.confirmEmail(token);

  Future<AppUser> updateProfile({
    String? name,
    String? theme,
    String? language,
    File? avatarFile,
  }) async {
    final data = await _api.updateProfile(
      name: name,
      theme: theme,
      language: language,
      avatarFile: avatarFile,
    );
    return AppUser.fromJson(data);
  }

  Future<void> requestEmailChange(String newEmail) => _api.requestEmailChange(newEmail);

  Future<AuthTokens> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    final tokens = await _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    await _storage.saveTokens(accessToken: tokens.access, refreshToken: tokens.refresh);
    return tokens;
  }
}
