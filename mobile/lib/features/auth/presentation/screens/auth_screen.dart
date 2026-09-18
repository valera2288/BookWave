import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_exception.dart';
import '../auth_controller.dart';
import 'password_reset_request_screen.dart';

/// Экран «Вход / Регистрация» из ТЗ: один экран с переключателем вкладок,
/// а не два отдельных — вход и регистрация используют общий root-route,
/// поэтому успешный сабмит с любой вкладки просто даёт `_AuthGate`
/// подменить этот экран на `HomeScreen` (пуш/поп не нужны).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

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
        setState(() => _lastErrorMessage = 'Необходимо принять пользовательское соглашение.');
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
    ref.listen(authControllerProvider, (previous, next) {
      // Реагируем только на переход loading → error, вызванный именно
      // этим сабмитом, а не на любое изменение состояния провайдера.
      if (previous?.isLoading != true || !next.hasError) return;
      final error = next.error;
      final message = error is AuthException ? error.message : 'Не удалось выполнить запрос.';
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
          tabs: const [Tab(text: 'Вход'), Tab(text: 'Регистрация')],
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
                      'Слишком много попыток. Повторите через $_lockoutSecondsRemaining с.',
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
                      child: const Text('Забыли пароль?'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _submitLabel(bool isLocked) {
    if (_isLoginTab) return isLocked ? 'Заблокировано ($_lockoutSecondsRemaining с)' : 'Войти';
    return 'Зарегистрироваться';
  }

  Widget _buildLoginForm() {
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
                (value == null || !value.contains('@')) ? 'Введите корректный e-mail' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Пароль',
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Введите пароль' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(labelText: 'Имя'),
            validator: (value) {
              final length = value?.trim().length ?? 0;
              if (length < 2 || length > 50) return 'Имя должно быть от 2 до 50 символов';
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
              if (value == null || !value.contains('@')) return 'Введите корректный e-mail';
              return _registerEmailServerError;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Пароль',
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
              if (value == null || value.length < 8) return 'Минимум 8 символов';
              if (!value.contains(RegExp(r'[0-9]'))) {
                return 'Пароль должен содержать минимум одну цифру';
              }
              return _registerPasswordServerError;
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            title: const Text('Принимаю пользовательское соглашение'),
          ),
        ],
      ),
    );
  }
}
