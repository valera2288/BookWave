import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../book_details/presentation/screens/book_detail_screen.dart';
import '../../../catalog/domain/book_summary.dart';
import '../../../catalog/presentation/widgets/book_card.dart';
import '../favorites_controller.dart';

final _favoritesListProvider = FutureProvider.autoDispose<List<BookSummary>>(
  (ref) => ref.watch(favoritesApiProvider).fetchFavorites(),
);

/// «Избранное» — отдельный экран в профиле (ТЗ), сетка карточек тем же
/// `BookCard`, что и в каталоге/на главной. Сердечко снимает книгу сразу
/// из этого списка через уже существующий `favoritesControllerProvider`.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(_favoritesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить избранное'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(_favoritesListProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text('Пока нет книг в избранном'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_favoritesListProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                // 0.6 переполнял карточку снизу на двухстрочных названиях
                // (тот же баг, что в BookRow на главной) — 0.5 даёт запас.
                childAspectRatio: 0.5,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookCard(
                  book: book,
                  isFavorite: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
                  ),
                  onFavoriteTap: () async {
                    try {
                      await ref.read(favoritesControllerProvider.notifier).toggle(book.id);
                      ref.invalidate(_favoritesListProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
