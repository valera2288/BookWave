import 'package:flutter/material.dart';

import '../../domain/book_summary.dart';

/// Карточка книги (обложка, название, автор, цена, рейтинг) — переиспользуется
/// в сетке каталога, блоке «Рекомендуем» и блоке «Новинки» на главной.
/// Иконка «Сердце» — тоже по ТЗ («добавление в избранное... на карточке
/// книги или в каталоге»).
class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    super.key,
  });

  final BookSummary book;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.cover != null
                        ? Image.network(
                            book.cover!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                          )
                        : const _CoverPlaceholder(),
                  ),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _FavoriteButton(onTap: onFavoriteTap!, isFavorite: isFavorite),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (book.authors.isNotEmpty)
            Text(
              book.authors.map((a) => a.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${book.price.toStringAsFixed(0)} ₽',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (book.ratingCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 2),
                    Text(book.averageRating!.toStringAsFixed(1), style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.onTap, required this.isFavorite});

  final VoidCallback onTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: isFavorite ? Colors.redAccent : Colors.white,
          ),
        ),
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
        size: 32,
      ),
    );
  }
}
