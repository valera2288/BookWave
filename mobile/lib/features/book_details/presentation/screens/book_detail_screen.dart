import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/ensure_authenticated.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../catalog/domain/book_detail.dart';
import '../../../catalog/presentation/language_label.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../library/domain/library_entry.dart';
import '../../../library/presentation/library_providers.dart';
import '../../../reader/presentation/screens/reader_screen.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../book_detail_providers.dart';

/// Карточка книги из ТЗ. «Читать фрагмент» открывает читалку в режиме
/// ознакомительного фрагмента (без покупки — сервер сам урезает содержимое
/// для не владеющих книгой пользователей, см. `apps/files/views.py`).
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final int bookId;

  void _notYetAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.notYetAvailableMessage(feature)),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    if (!ensureAuthenticated(context, ref)) return;
    try {
      await ref.read(favoritesControllerProvider.notifier).toggle(bookId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openExcerpt(BuildContext context, BookDetail book) {
    if (book.availableFormats.isEmpty) {
      _notYetAvailable(context, AppLocalizations.of(context)!.featureExcerptReading);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          bookId: book.id,
          title: book.title,
          format: book.preferredFormat,
          isExcerpt: true,
        ),
      ),
    );
  }

  void _openOwnedBook(BuildContext context, BookDetail book, LibraryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          bookId: book.id,
          title: book.title,
          format: entry.preferredFormat,
          isExcerpt: false,
          initialProgress: entry.progress,
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    if (!ensureAuthenticated(context, ref)) return;
    try {
      final added = await ref.read(cartControllerProvider.notifier).addBook(bookId);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(added ? l10n.bookDetailAddedToCart : l10n.bookDetailAlreadyInCart)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookAsync = ref.watch(bookDetailProvider(bookId));
    final isFavorite =
        (ref.watch(favoritesControllerProvider).valueOrNull ?? const {}).contains(bookId);
    // Книга уже куплена (есть в библиотеке) — сервер и так отклонит
    // «Добавить в корзину» с ошибкой (`apps/cart/views.py`), но пользователь
    // не должен об этом узнавать только по факту нажатия кнопки.
    final libraryEntries = ref.watch(libraryProvider).valueOrNull ?? const <LibraryEntry>[];
    LibraryEntry? ownedEntry;
    for (final entry in libraryEntries) {
      if (entry.book.id == bookId) {
        ownedEntry = entry;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookDetailTitle)),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.bookDetailLoadError),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (book) => _BookDetailBody(
          book: book,
          isFavorite: isFavorite,
          ownedEntry: ownedEntry,
          onFavoriteTap: () => _toggleFavorite(context, ref),
          onCartTap: () => _addToCart(context, ref),
          onExcerptTap: () => _openExcerpt(context, book),
          onReadTap: ownedEntry == null ? null : () => _openOwnedBook(context, book, ownedEntry!),
        ),
      ),
    );
  }
}

class _BookDetailBody extends StatelessWidget {
  const _BookDetailBody({
    required this.book,
    required this.isFavorite,
    required this.ownedEntry,
    required this.onFavoriteTap,
    required this.onCartTap,
    required this.onExcerptTap,
    required this.onReadTap,
  });

  final BookDetail book;
  final bool isFavorite;
  final LibraryEntry? ownedEntry;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCartTap;
  final VoidCallback onExcerptTap;
  final VoidCallback? onReadTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: book.cover != null
                      ? Image.network(
                          book.cover!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                        )
                      : const _CoverPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    if (book.authors.isNotEmpty)
                      Text(
                        book.authors.map((a) => a.name).join(', '),
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          book.ratingCount > 0
                              ? '${book.averageRating!.toStringAsFixed(1)} (${book.ratingCount})'
                              : l10n.bookDetailNoRatings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (ownedEntry != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.bookDetailAlreadyOwned,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${book.price.toStringAsFixed(0)} ₽',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : null,
                  ),
                  label: Text(isFavorite ? l10n.bookDetailFavorited : l10n.bookDetailAddToFavorites),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ownedEntry == null
                    ? FilledButton.icon(
                        onPressed: onCartTap,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(l10n.bookDetailAddToCart),
                      )
                    : FilledButton.icon(
                        onPressed: onReadTap,
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l10n.bookDetailRead),
                      ),
              ),
            ],
          ),
          if (ownedEntry == null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onExcerptTap,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.bookDetailReadExcerpt),
            ),
          ],
          const SizedBox(height: 24),
          _InfoRow(label: l10n.bookDetailGenre, value: book.genres.map((g) => g.name).join(', ')),
          _InfoRow(
            label: l10n.bookDetailLanguage,
            value: languageDisplayName(book.language, l10n),
          ),
          if (book.publisher.isNotEmpty)
            _InfoRow(label: l10n.bookDetailPublisher, value: book.publisher),
          if (book.publicationYear != null)
            _InfoRow(label: l10n.bookDetailPublicationYear, value: '${book.publicationYear}'),
          if (book.pageCount != null)
            _InfoRow(label: l10n.bookDetailPageCount, value: l10n.bookDetailPages(book.pageCount!)),
          if (book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.bookDetailDescription, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(book.description),
          ],
          const SizedBox(height: 16),
          Text(l10n.bookDetailReviews, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ReviewsSection(bookId: book.id),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
