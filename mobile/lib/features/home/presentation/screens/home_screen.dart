import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/ensure_authenticated.dart';
import '../../../book_details/presentation/screens/book_detail_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../catalog/domain/book_summary.dart';
import '../../../catalog/presentation/catalog_controller.dart';
import '../../../catalog/presentation/catalog_reference_providers.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../home_providers.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/book_row.dart';
import '../widgets/genre_tiles.dart';

/// Главный экран из ТЗ: приветствие, иконка корзины (открывает `CartScreen`)
/// и иконка библиотеки (открывает `LibraryScreen` — тот же экран, что и на
/// вкладке «Библиотека» внизу, второй быстрый вход по образцу корзины),
/// баннеры, «Новинки», «Топ продаж», «Рекомендуем», «Жанры».
///
/// `user == null` — роль «Гость» (ТЗ): та же главная, но без имени в
/// приветствии, без блока «Рекомендуем» (персонализация требует покупок/
/// избранного) и с действиями корзины/библиотеки/избранного, уводящими на
/// экран входа вместо самого действия.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.user, super.key});

  final AppUser? user;

  void _notYetAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.notYetAvailableMessage(feature)),
      ),
    );
  }

  void _openBook(BuildContext context, int bookId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, BookSummary book) async {
    if (!ensureAuthenticated(context, ref)) return;
    try {
      await ref.read(favoritesControllerProvider.notifier).toggle(book.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Каталог поверх главной (плитка жанра, баннер-раздел) — со своим
  /// экземпляром `catalogControllerProvider`, иначе фильтр жанра оставался
  /// бы висеть на вкладке «Каталог» после возврата.
  void _openCatalog(BuildContext context, {int? genreId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [catalogControllerProvider.overrideWith(CatalogController.new)],
          child: CatalogScreen(initialGenreId: genreId),
        ),
      ),
    );
  }

  /// `Banner.link_url` для раздела каталога: `catalog` или `catalog?genre=<id>`.
  void _openBannerLink(BuildContext context, String linkUrl) {
    if (linkUrl.startsWith('http')) {
      // Внешние ссылки требуют url_launcher — пакета в проекте нет.
      _notYetAvailable(context, AppLocalizations.of(context)!.featureBannerLink);
      return;
    }
    final genreMatch = RegExp(r'genre=(\d+)').firstMatch(linkUrl);
    _openCatalog(context, genreId: genreMatch == null ? null : int.parse(genreMatch.group(1)!));
  }

  void _openCart(BuildContext context, WidgetRef ref) {
    if (!ensureAuthenticated(context, ref)) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  void _openLibrary(BuildContext context, WidgetRef ref) {
    if (!ensureAuthenticated(context, ref)) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bannersAsync = ref.watch(activeBannersProvider);
    final newestAsync = ref.watch(newestBooksProvider);
    final topSellersAsync = ref.watch(topSellersProvider);
    // Рекомендации персонализированы (по избранному/покупкам) и на бэкенде
    // требуют авторизацию (`RecommendationsView`, `permission_classes =
    // [IsAuthenticated]`) — гостю их не запрашиваем вовсе, не только не
    // показываем.
    final recommendationsAsync = user == null ? null : ref.watch(recommendationsProvider);
    final genresAsync = ref.watch(genresProvider);
    final favoriteBookIds = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? l10n.homeGreeting(user!.name) : l10n.homeGreetingGuest),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.navLibrary,
            onPressed: () => _openLibrary(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: l10n.navCart,
            onPressed: () => _openCart(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBannersProvider);
          ref.invalidate(newestBooksProvider);
          ref.invalidate(topSellersProvider);
          if (user != null) ref.invalidate(recommendationsProvider);
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
                  } else if (banner.linkUrl.isNotEmpty) {
                    _openBannerLink(context, banner.linkUrl);
                  }
                },
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            newestAsync.maybeWhen(
              data: (books) => BookRow(
                title: l10n.homeSectionNewest,
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
                title: l10n.homeSectionTopSellers,
                books: books,
                onBookTap: (book) => _openBook(context, book.id),
                favoriteBookIds: favoriteBookIds,
                onFavoriteToggle: (book) => _toggleFavorite(context, ref, book),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            if (recommendationsAsync != null) ...[
              const SizedBox(height: 16),
              recommendationsAsync.maybeWhen(
                data: (books) => BookRow(
                  title: l10n.homeSectionRecommended,
                  books: books,
                  onBookTap: (book) => _openBook(context, book.id),
                  favoriteBookIds: favoriteBookIds,
                  onFavoriteToggle: (book) => _toggleFavorite(context, ref, book),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
            const SizedBox(height: 16),
            genresAsync.maybeWhen(
              data: (genres) => GenreTiles(
                genres: genres,
                onGenreTap: (genre) => _openCatalog(context, genreId: genre.id),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
