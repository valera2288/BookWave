import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/cart_controller.dart';
import '../../../catalog/domain/book_detail.dart';
import '../../../favorites/presentation/favorites_controller.dart';
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
      SnackBar(content: Text('$feature появится в одной из следующих фаз.')),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
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
      _notYetAvailable(context, 'Чтение фрагмента');
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

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    try {
      final added = await ref.read(cartControllerProvider.notifier).addBook(bookId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(added ? 'Добавлено в корзину' : 'Уже в корзине')),
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
    final bookAsync = ref.watch(bookDetailProvider(bookId));
    final isFavorite =
        (ref.watch(favoritesControllerProvider).valueOrNull ?? const {}).contains(bookId);

    return Scaffold(
      appBar: AppBar(title: const Text('Книга')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить книгу'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (book) => _BookDetailBody(
          book: book,
          isFavorite: isFavorite,
          onFavoriteTap: () => _toggleFavorite(context, ref),
          onCartTap: () => _addToCart(context, ref),
          onExcerptTap: () => _openExcerpt(context, book),
        ),
      ),
    );
  }
}

class _BookDetailBody extends StatelessWidget {
  const _BookDetailBody({
    required this.book,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onCartTap,
    required this.onExcerptTap,
  });

  final BookDetail book;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCartTap;
  final VoidCallback onExcerptTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                              : 'Нет оценок',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                  label: Text(isFavorite ? 'В избранном' : 'В избранное'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCartTap,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Добавить в корзину'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onExcerptTap,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Читать фрагмент'),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: 'Жанр', value: book.genres.map((g) => g.name).join(', ')),
          _InfoRow(label: 'Язык', value: book.language),
          if (book.publisher.isNotEmpty) _InfoRow(label: 'Издательство', value: book.publisher),
          if (book.publicationYear != null)
            _InfoRow(label: 'Год издания', value: '${book.publicationYear}'),
          if (book.pageCount != null) _InfoRow(label: 'Объём', value: '${book.pageCount} стр.'),
          if (book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Описание', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(book.description),
          ],
          const SizedBox(height: 16),
          Text('Отзывы', style: theme.textTheme.titleMedium),
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
