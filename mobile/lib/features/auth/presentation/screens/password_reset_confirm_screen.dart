import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/auth_exception.dart';

/// Токен обычно приходит уже подставленным — пользователь открыл письмо
/// со ссылкой `bookwave://reset-password/<token>`, диплинк передал сюда
/// [initialToken] (см. `_DeepLinkListener` в `app.dart`). Ручной ввод
/// токена остаётся как запасной путь на случай, если ссылка открылась
/// не в приложении (например, на десктопе при разработке).
class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  const PasswordResetConfirmScreen({this.initialToken, super.key});

  final String? initialToken;

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState
    extends ConsumerState<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(text: widget.initialToken);
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _hasTokenFromLink => (widget.initialToken ?? '').isNotEmpty;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
            newPassword2: _passwordConfirmController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.authPasswordChangedMessage)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authNewPassword)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_hasTokenFromLink) ...[
                      TextFormField(
                        controller: _tokenController,
                        decoration: InputDecoration(
                          labelText: l10n.authTokenLabel,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? l10n.authTokenRequired : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.authNewPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) return l10n.authPasswordMinLength;
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return l10n.authPasswordNeedsDigit;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(labelText: l10n.authRepeatPasswordLabel),
                      validator: (value) => value != _passwordController.text
                          ? l10n.authPasswordsMismatch
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.authSavePassword),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
