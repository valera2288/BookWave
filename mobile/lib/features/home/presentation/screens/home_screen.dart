import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/app_user.dart';
import '../../../book_details/presentation/screens/book_detail_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../catalog/domain/book_summary.dart';
import '../../../catalog/presentation/catalog_reference_providers.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../home_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/book_row.dart';
import '../widgets/genre_tiles.dart';

/// Главный экран из ТЗ: приветствие, иконка корзины (открывает `CartScreen`)
/// и иконка библиотеки (открывает `LibraryScreen` — тот же экран, что и на
/// вкладке «Библиотека» внизу, второй быстрый вход по образцу корзины),
/// баннеры, «Новинки», «Топ продаж», «Рекомендуем», «Жанры».
class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.user, super.key});

  final AppUser user;

  void _notYetAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature появится в одной из следующих фаз.')),
    );
  }

  void _openBook(BuildContext context, int bookId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, BookSummary book) async {
    try {
      await ref.read(favoritesControllerProvider.notifier).toggle(book.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);
    final newestAsync = ref.watch(newestBooksProvider);
    final topSellersAsync = ref.watch(topSellersProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final genresAsync = ref.watch(genresProvider);
    final favoriteBookIds = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Здравствуйте, ${user.name}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Библиотека',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Корзина',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBannersProvider);
          ref.invalidate(newestBooksProvider);
          ref.invalidate(topSellersProvider);
          ref.invalidate(recommendationsProvider);
          ref.invalidate(genresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            bannersAsync.maybeWhen(
              data: (banners) => BannerCarousel(
                banners: banners,
                onTap: (banner) {
                  if (banner.linkBook != null) {
                    _openBook(context, banner.linkBook!);
                  } else {
                    _notYetAvailable(context, 'Переход по ссылке баннера');
                  }
                },
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            newestAsync.maybeWhen(
              data: (books) => BookRow(
                title: 'Новинки',
                books: books,
                onBookTap: (book) => _openBook(context, book.id),
                favoriteBookIds: favoriteBookIds,
                onFavoriteToggle: (book) => _toggleFavorite(context, ref, book),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            topSellersAsync.maybeWhen(
              data: (books) => BookRow(
                title: 'Топ продаж',
                books: books,
                onBookTap: (book) => _openBook(context, book.id),
                favoriteBookIds: favoriteBookIds,
                onFavoriteToggle: (book) => _toggleFavorite(context, ref, book),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            recommendationsAsync.maybeWhen(
              data: (books) => BookRow(
                title: 'Рекомендуем',
                books: books,
                onBookTap: (book) => _openBook(context, book.id),
                favoriteBookIds: favoriteBookIds,
                onFavoriteToggle: (book) => _toggleFavorite(context, ref, book),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            genresAsync.maybeWhen(
              data: (genres) => GenreTiles(
                genres: genres,
                onGenreTap: (genre) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CatalogScreen(initialGenreId: genre.id),
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
