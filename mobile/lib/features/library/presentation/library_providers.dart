import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/library_entry.dart';

final libraryProvider = FutureProvider<List<LibraryEntry>>((ref) async {
  // Гость не авторизован — эндпоинт всё равно ответит 401, не тратим на
  // него запрос и просто считаем библиотеку пустой (используется и для
  // определения владения книгой на карточке/в отзывах).
  final user = await ref.watch(authControllerProvider.future);
  if (user == null) return const <LibraryEntry>[];
  return (await ref.watch(libraryApiProvider).fetchLibrary()).entries;
});
