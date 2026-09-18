import 'package:flutter/material.dart';

import '../../../catalog/domain/book_summary.dart';
import '../../../catalog/presentation/widgets/book_card.dart';

/// Горизонтальный ряд книг с заголовком — переиспользуется для блоков
/// «Новинки» и «Рекомендуем» на главной.
class BookRow extends StatelessWidget {
  const BookRow({
    required this.title,
    required this.books,
    required this.onBookTap,
    this.favoriteBookIds = const {},
    this.onFavoriteToggle,
    super.key,
  });

  final String title;
  final List<BookSummary> books;
  final ValueChanged<BookSummary> onBookTap;
  final Set<int> favoriteBookIds;
  final ValueChanged<BookSummary>? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        SizedBox(
          // 248 не хватало под двухстрочные названия книг ("Гордость и
          // предубеждение" и т.п.) — карточка переполнялась снизу на
          // 13px. С запасом на случай ещё более длинных заголовков.
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return SizedBox(
                width: 130,
                child: BookCard(
                  book: book,
                  onTap: () => onBookTap(book),
                  isFavorite: favoriteBookIds.contains(book.id),
                  onFavoriteTap: onFavoriteToggle == null ? null : () => onFavoriteToggle!(book),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
