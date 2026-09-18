import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/reader_bookmark.dart';

/// `autoDispose` обязателен: сервер решает фрагмент/полный файл по
/// владению книгой на момент запроса (см. `ReaderApi.downloadBookFile`).
/// Без autoDispose провайдер держал бы скачанный файл в памяти вечно по
/// ключу (bookId, format) — открыл «Читать фрагмент» до покупки, потом
/// купил и открыл ту же книгу из библиотеки — получил бы из кэша тот же
/// файл с фрагментом вместо нового запроса за полным текстом.
final readerFileProvider =
    FutureProvider.family.autoDispose<File, ({int bookId, String format})>(
  (ref, args) =>
      ref.watch(readerApiProvider).downloadBookFile(bookId: args.bookId, format: args.format),
);

final bookmarksProvider =
    AsyncNotifierProvider.family<BookmarksController, List<ReaderBookmark>, int>(
  BookmarksController.new,
);

/// Закладки одной книги — с оптимистичным добавлением/удалением, как
/// `FavoritesController` (см. `features/favorites/presentation/favorites_controller.dart`).
class BookmarksController extends FamilyAsyncNotifier<List<ReaderBookmark>, int> {
  @override
  Future<List<ReaderBookmark>> build(int bookId) =>
      ref.read(bookmarksApiProvider).fetchBookmarks(bookId);

  Future<void> add(String position) async {
    final current = state.valueOrNull ?? const <ReaderBookmark>[];
    final created = await ref.read(bookmarksApiProvider).addBookmark(
          bookId: arg,
          position: position,
        );
    state = AsyncData([...current, created]);
  }

  Future<void> remove(int id) async {
    final current = state.valueOrNull ?? const <ReaderBookmark>[];
    state = AsyncData(current.where((b) => b.id != id).toList());
    try {
      await ref.read(bookmarksApiProvider).removeBookmark(id);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
