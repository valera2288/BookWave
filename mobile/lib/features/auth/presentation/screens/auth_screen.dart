import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_exception.dart';
import '../auth_controller.dart';
import 'password_reset_request_screen.dart';

/// Экран «Вход / Регистрация» из ТЗ: один экран с переключателем вкладок,
/// а не два отдельных. Как root-route `_AuthGate` (гость ещё не выбрал,
/// входить или нет) успешный сабмит просто даёт `_AuthGate` подменить этот
/// экран на `MainShell` (пуш/поп не нужны). Как экран, запушенный поверх
/// гостевого режима (см. `ensureAuthenticated`) — сам закрывается по
/// успешному входу через `Navigator.pop`, см. `ref.listen` ниже.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({this.onContinueAsGuest, super.key});

  /// Задан только когда экран показан как root (`_AuthGate`, гость ещё не
  /// выбирал) — тогда «Продолжить как гость» переключает `_AuthGate` в
  /// гостевой режим. Если экран запушен поверх уже открытого гостевого
  /// режима, `null`, и кнопка просто закрывает этот экран (`Navigator.pop`).
  final VoidCallback? onContinueAsGuest;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _obscureRegisterPassword = true;
  bool _acceptTerms = false;

  // Ошибки, которые сервер обнаруживает только при сабмите (пароль в
  // списке распространённых, email уже занят) — показываем прямо под
  // полем, а не только снекбаром, который легко пропустить.
  String? _registerPasswordServerError;
  String? _registerEmailServerError;

  // Снекбар легко пропустить (и в этой сборке он, похоже, вообще не был
  // замечен пользователем) — дублируем ошибку постоянным баннером прямо в
  // форме, который висит, пока не начнут новый сабмит или не сменят вкладку.
  String? _lastErrorMessage;

  Timer? _lockoutTimer;
  int _lockoutSecondsRemaining = 0;

  bool get _isLoginTab => _tabController.index == 0;

  void _continueAsGuest() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onContinueAsGuest?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() => _lastErrorMessage = null);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ТЗ: после 3 неудачных попыток подряд форма входа должна на 60 секунд
  // блокировать повторную отправку — сервер сообщает retry_after, здесь
  // просто отсчитываем его и держим кнопку неактивной.
  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() => _lockoutSecondsRemaining = seconds);
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _lockoutSecondsRemaining = 0);
      } else {
        setState(() => _lockoutSecondsRemaining -= 1);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _lastErrorMessage = null);
    if (_isLoginTab) {
      if (_lockoutSecondsRemaining > 0) return;
      if (!_loginFormKey.currentState!.validate()) return;
      await ref.read(authControllerProvider.notifier).login(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text,
          );
    } else {
      if (!_registerFormKey.currentState!.validate()) return;
      if (!_acceptTerms) {
        setState(
          () => _lastErrorMessage = AppLocalizations.of(context)!.authAcceptTermsRequired,
        );
        return;
      }
      await ref.read(authControllerProvider.notifier).register(
            email: _registerEmailController.text.trim(),
            name: _registerNameController.text.trim(),
            password: _registerPasswordController.text,
            acceptTerms: _acceptTerms,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(authControllerProvider, (previous, next) {
      // Успешный вход из гостевого режима: этот экран был запушен поверх
      // (см. ensureAuthenticated) — сам себя закрывает, открывая уже
      // обновлённый `MainShell` под собой. Как root-route `_AuthGate` не
      // даёт этому экрану ничего попнуть, так что здесь no-op.
      if (previous?.isLoading == true && next.hasValue && next.value != null) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        return;
      }
      // Реагируем только на переход loading → error, вызванный именно
      // этим сабмитом, а не на любое изменение состояния провайдера.
      if (previous?.isLoading != true || !next.hasError) return;
      final error = next.error;
      final message = error is AuthException ? error.message : l10n.authGenericError;
      final isLockoutError = error is AuthException && error.retryAfter != null && _isLoginTab;
      if (isLockoutError) {
        _startLockoutCountdown(error.retryAfter!);
      }
      if (error is AuthException && !_isLoginTab && error.field == 'password') {
        setState(() => _registerPasswordServerError = error.message);
        _registerFormKey.currentState?.validate();
      }
      if (error is AuthException && !_isLoginTab && error.field == 'email') {
        setState(() => _registerEmailServerError = error.message);
        _registerFormKey.currentState?.validate();
      }
      // При блокировке формы (60с) сообщение уже показывает отдельный
      // живой счётчик ниже — не дублируем его статичным баннером.
      if (!isLockoutError) {
        setState(() => _lastErrorMessage = message);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final isLocked = _isLoginTab && _lockoutSecondsRemaining > 0;
    final isDisabled = isLoading || isLocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookWave'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.authTabLogin), Tab(text: l10n.authTabRegister)],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _isLoginTab ? _buildLoginForm() : _buildRegisterForm(),
                  if (_lastErrorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastErrorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isLocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.authLockoutMessage(_lockoutSecondsRemaining),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: isDisabled ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_submitLabel(isLocked)),
                  ),
                  if (_isLoginTab) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isDisabled
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PasswordResetRequestScreen(),
                                ),
                              ),
                      child: Text(l10n.authForgotPassword),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isDisabled ? null : _continueAsGuest,
                    child: Text(l10n.authContinueAsGuest),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _submitLabel(bool isLocked) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoginTab) {
      return isLocked ? l10n.authLockedButton(_lockoutSecondsRemaining) : l10n.authLoginButton;
    }
    return l10n.authRegisterButton;
  }

  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: (value) =>
                (value == null || !value.contains('@')) ? l10n.authEmailInvalid : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.authPasswordLabel,
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? l10n.authPasswordRequired : null,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: InputDecoration(labelText: l10n.authNameLabel),
            validator: (value) {
              final length = value?.trim().length ?? 0;
              if (length < 2 || length > 50) return l10n.authNameLengthError;
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            onChanged: (_) {
              if (_registerEmailServerError != null) {
                setState(() => _registerEmailServerError = null);
              }
            },
            validator: (value) {
              if (value == null || !value.contains('@')) return l10n.authEmailInvalid;
              return _registerEmailServerError;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.authPasswordLabel,
              suffixIcon: IconButton(
                icon: Icon(_obscureRegisterPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              ),
            ),
            onChanged: (_) {
              if (_registerPasswordServerError != null) {
                setState(() => _registerPasswordServerError = null);
              }
            },
            validator: (value) {
              if (value == null || value.length < 8) return l10n.authPasswordMinLength;
              if (!value.contains(RegExp(r'[0-9]'))) {
                return l10n.authPasswordNeedsDigit;
              }
              return _registerPasswordServerError;
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            title: Text(l10n.authAcceptTermsLabel),
          ),
        ],
      ),
    );
  }
}
