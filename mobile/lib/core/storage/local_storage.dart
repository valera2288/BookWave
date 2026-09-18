import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Несекретные настройки (тема, язык) — SharedPreferences.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPreferences> create() async {
    return AppPreferences(await SharedPreferences.getInstance());
  }

  String? get themeMode => _prefs.getString('theme_mode');
  Future<void> setThemeMode(String value) => _prefs.setString('theme_mode', value);

  String? get locale => _prefs.getString('locale');
  Future<void> setLocale(String value) => _prefs.setString('locale', value);

  /// «Экран приветствия» из ТЗ показывается только один раз, до первого
  /// входа/регистрации — дальше приложение переходит сразу к входу.
  bool get hasSeenOnboarding => _prefs.getBool('has_seen_onboarding') ?? false;
  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool('has_seen_onboarding', value);

  // Настройки читалки (ТЗ: шрифт, тема, режим навигации) — отдельная от
  // темы приложения концепция, поэтому не через AppTheme.
  int get readerFontSizeIndex => _prefs.getInt('reader_font_size_index') ?? 2;
  Future<void> setReaderFontSizeIndex(int value) =>
      _prefs.setInt('reader_font_size_index', value);

  /// 'light' | 'dark' | 'sepia'
  String get readerTheme => _prefs.getString('reader_theme') ?? 'light';
  Future<void> setReaderTheme(String value) => _prefs.setString('reader_theme', value);

  bool get readerContinuousScroll => _prefs.getBool('reader_continuous_scroll') ?? false;
  Future<void> setReaderContinuousScroll(bool value) =>
      _prefs.setBool('reader_continuous_scroll', value);

  /// Псевдо-токен устройства для push вместо настоящего FCM (решение по
  /// Фазе 8 — нет реального Firebase-проекта; бэкенд тоже пока только
  /// печатает push в консоль вместо реальной отправки, см.
  /// `apps/notifications/services.py`). Генерируется один раз при первом
  /// обращении и переиспользуется, чтобы каждый перезапуск приложения не
  /// плодил новую запись `DeviceToken` на бэкенде.
  String get deviceToken {
    final existing = _prefs.getString('device_token');
    if (existing != null) return existing;
    final generated = _generateDeviceToken();
    _prefs.setString('device_token', generated);
    return generated;
  }

  static String _generateDeviceToken() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

/// Токены сессии — FlutterSecureStorage, не в открытом виде.
class SecureSessionStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
