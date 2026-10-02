import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../../home/presentation/home_providers.dart';
import '../../home/presentation/main_shell.dart';
import '../../library/presentation/library_providers.dart';
import '../../orders/presentation/orders_providers.dart';
import '../../reader/presentation/reader_providers.dart';
import '../../reader/presentation/reader_settings_controller.dart';
import '../../reviews/presentation/reviews_controller.dart';
import '../data/auth_exception.dart';
import '../domain/app_user.dart';

/// `null` в данных — гость (не аутентифицирован). `AsyncLoading` во время
/// восстановления сессии/входа/регистрации, `AsyncError` — последняя
/// попытка не удалась (экран решает, как показать `error`).
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    try {
      final user = await repository.restoreSession();
      if (user != null) _registerDeviceToken();
      return user;
    } on AuthException catch (e) {
      // 401 — токены действительно недействительны (refresh не помог):
      // сессии нет. Любая другая ошибка (нет сети, сервер недоступен) —
      // токены сохраняем, иначе ТЗ-шный автовход терялся бы от одного
      // запуска без интернета; _AuthGate покажет экран «Повторить».
      if (e.statusCode == 401) {
        await repository.logout();
        return null;
      }
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final repository = ref.read(authRepositoryProvider);
    // `copyWithPrevious` — иначе _AuthGate (ref.watch) увидит "голый"
    // AsyncLoading без прежнего значения и посчитает это холодным стартом
    // сессии, подменив AuthScreen на _SplashScreen прямо посреди сабмита —
    // старый AuthScreen с его ref.listen на ошибку уничтожится, новый
    // подпишется уже post factum и пропустит переход loading → error.
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => repository.login(email: email, password: password),
    );
    if (state.value != null) _registerDeviceToken();
  }

  Future<void> register({
    required String email,
    required String name,
    required String password,
    required bool acceptTerms,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => repository.register(
        email: email,
        name: name,
        password: password,
        acceptTerms: acceptTerms,
      ),
    );
    if (state.value != null) _registerDeviceToken();
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await _unregisterDeviceToken();
    await repository.logout();
    state = const AsyncData(null);
    _clearUserScopedCaches();
  }

  /// На том же устройстве может войти другой аккаунт — без явной очистки
  /// эти провайдеры (кроме `authControllerProvider`, уже сброшен выше)
  /// кешируются на уровне приложения, а не сессии, и next-пользователь
  /// увидел бы чужую библиотеку/корзину/заказы/закладки до первого
  /// естественного invalidate (см. ТЗ: доступ к чужой библиотеке и
  /// заказам запрещён независимо от корректности запроса — это касается
  /// и клиентского кеша, не только серверных проверок).
  void _clearUserScopedCaches() {
    ref.invalidate(cartControllerProvider);
    ref.invalidate(favoritesControllerProvider);
    ref.invalidate(libraryProvider);
    ref.invalidate(orderHistoryProvider);
    ref.invalidate(orderDetailProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(reviewsProvider);
    ref.invalidate(bookmarksProvider);
    // Не привязана к аккаунту (хранится локально в appPreferencesProvider,
    // не с сервера) — реального риска утечки между пользователями нет, но
    // сбрасываем заодно, чтобы provider-состояние логаута было единообразным.
    ref.invalidate(readerSettingsProvider);
    ref.read(mainShellTabIndexProvider.notifier).state = 0;
  }

  /// Best-effort побочный эффект — сбой регистрации/отвязки токена не
  /// должен ронять вход/выход из аккаунта, поэтому ошибки не пробрасываются.
  /// Windows-десктоп — только dev-тестирование (BlueStacks —
  /// единственная Android-цель), не реальная push-платформа, поэтому
  /// токен там не регистрируем — `DeviceToken.platform` на бэкенде вообще
  /// не знает значения "windows".
  Future<void> _registerDeviceToken() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final prefs = await ref.read(appPreferencesProvider.future);
      await ref.read(notificationsApiProvider).registerDeviceToken(
            token: prefs.deviceToken,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
    } catch (_) {
      // Не критично — карточка книги/каталог не должны падать из-за push.
    }
  }

  Future<void> _unregisterDeviceToken() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final prefs = await ref.read(appPreferencesProvider.future);
      await ref.read(notificationsApiProvider).unregisterDeviceToken(prefs.deviceToken);
    } catch (_) {
      // Не критично — выход из аккаунта не должен блокироваться этим.
    }
  }

  /// Перечитывает профиль (например, после подтверждения e-mail по
  /// диплинку) — молча, без loading-состояния, чтобы не мигать экраном,
  /// и только если пользователь и так уже авторизован на устройстве.
  Future<void> refreshUser() async {
    if (state.value == null) return;
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.restoreSession();
    if (user != null) state = AsyncData(user);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
