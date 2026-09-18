import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_exception.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/password_reset_confirm_screen.dart';
import 'features/home/presentation/main_shell.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

class BookWaveApp extends ConsumerWidget {
  const BookWaveApp({super.key});

  /// Тема — из профиля («Читатель» настраивает её в «Настройках»); у
  /// гостя/до входа профиля ещё нет, тогда — системная.
  ThemeMode _themeModeFor(WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    switch (user?.theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BookWave',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeModeFor(ref),
      home: const _DeepLinkListener(child: _AuthGate()),
    );
  }
}

/// Диплинки из писем: `bookwave://reset-password/<token>` и
/// `bookwave://confirm-email/<token>` (intent-filter/URL scheme — см.
/// AndroidManifest.xml, Info.plist и `FRONTEND_*_URL_BASE` в
/// backend/config/settings/base.py). Ловит и холодный старт по ссылке, и
/// открытие ссылки при уже запущенном приложении.
class _DeepLinkListener extends ConsumerStatefulWidget {
  const _DeepLinkListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<_DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _appLinks.getInitialLink().then(_handleUri);
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleUri(Uri? uri) {
    if (uri == null || uri.scheme != 'bookwave') return;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (token == null || token.isEmpty) return;

    switch (uri.host) {
      case 'reset-password':
        _openPasswordResetForm(token);
      case 'confirm-email':
        _confirmEmail(token);
    }
  }

  // Навигация/провайдеры синхронно из initState()/стрима могут попасть на
  // кадр построения виджетов — откладываем на кадр после текущего.
  void _openPasswordResetForm(String token) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasswordResetConfirmScreen(initialToken: token),
        ),
      );
    });
  }

  void _confirmEmail(String token) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(authRepositoryProvider).confirmEmail(token);
        await ref.read(authControllerProvider.notifier).refreshUser();
        messenger.showSnackBar(const SnackBar(content: Text('E-mail подтверждён.')));
      } on AuthException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Показывает сплэш, пока восстанавливается сессия, дальше — (для нового
/// устройства, ещё не входившего в аккаунт) экран приветствия один раз,
/// потом логин или домашний экран в зависимости от `authControllerProvider`.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  // null — ещё не читали AppPreferences в этой сессии виджета.
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    ref.read(appPreferencesProvider.future).then((prefs) {
      if (mounted) setState(() => _hasSeenOnboarding = prefs.hasSeenOnboarding);
    });
  }

  void _finishOnboarding() {
    ref.read(appPreferencesProvider.future).then((prefs) => prefs.setHasSeenOnboarding(true));
    setState(() => _hasSeenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Сплэш — только для настоящего холодного старта (ни значения, ни
    // ошибки ещё не было ни разу). AsyncLoading от login()/register()
    // несёт предыдущее значение через copyWithPrevious (см. AuthController)
    // и сюда не попадает — иначе AuthScreen пересоздавался бы посреди
    // сабмита, теряя форму и не успевая показать ошибку.
    final isColdStart = authState.isLoading && !authState.hasValue && !authState.hasError;
    if (isColdStart) {
      return const _SplashScreen();
    }

    final user = authState.valueOrNull;
    if (user != null) {
      // Уже вошедшему пользователю онбординг не показывается.
      return MainShell(user: user);
    }

    if (_hasSeenOnboarding == null) {
      return const _SplashScreen();
    }
    if (!_hasSeenOnboarding!) {
      return OnboardingScreen(onFinish: _finishOnboarding);
    }
    return const AuthScreen();
  }
}

/// «Экран загрузки» из ТЗ: логотип BookWave по центру, анимация загрузки.
/// Пока восстанавливается сессия (обычно доли секунды — дольше только при
/// живом запросе к `/users/me/`).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BookWave', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
