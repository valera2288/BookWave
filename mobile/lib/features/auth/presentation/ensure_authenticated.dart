import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'screens/auth_screen.dart';

/// Действия, доступные только «Читателю» (корзина, избранное, библиотека,
/// отзывы — см. ТЗ, роль «Гость»), вызывают это перед собой. Гостю вместо
/// действия открывается экран входа; возвращает `true`, если пользователь
/// уже авторизован и действие можно выполнять как обычно.
bool ensureAuthenticated(BuildContext context, WidgetRef ref) {
  final isAuthenticated = ref.read(authControllerProvider).valueOrNull != null;
  if (!isAuthenticated) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }
  return isAuthenticated;
}
