import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/auth_controller.dart';

/// Id избранных книг текущего пользователя — этого достаточно, чтобы
/// отрисовать состояние сердечка на карточке/детали книги (сам список
/// «Избранное» — отдельный экран в Phase 9, вместе с профилем).
class FavoritesController extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    // Гость не авторизован — эндпоинт всё равно ответит 401, не тратим на
    // него запрос и просто считаем список избранного пустым.
    final user = await ref.watch(authControllerProvider.future);
    if (user == null) return const <int>{};
    return ref.read(favoritesApiProvider).fetchFavoriteBookIds();
  }

  Future<void> toggle(int bookId) async {
    final current = state.valueOrNull ?? const <int>{};
    final wasFavorite = current.contains(bookId);
    final optimistic = {...current};
    wasFavorite ? optimistic.remove(bookId) : optimistic.add(bookId);
    state = AsyncData(optimistic);

    final api = ref.read(favoritesApiProvider);
    try {
      if (wasFavorite) {
        await api.removeFavorite(bookId);
      } else {
        await api.addFavorite(bookId);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final favoritesControllerProvider = AsyncNotifierProvider<FavoritesController, Set<int>>(
  FavoritesController.new,
);
