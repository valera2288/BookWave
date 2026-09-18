import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../book_details/presentation/book_detail_providers.dart';
import '../../../library/presentation/library_providers.dart';
import '../../../orders/presentation/order_date_format.dart';
import '../../domain/review.dart';
import '../reviews_controller.dart';

/// Блок отзывов на карточке книги (ТЗ): список чужих отзывов с
/// пролистыванием, и форма «оставить отзыв» — доступна только владельцам
/// книги (есть запись в библиотеке), сервер проверяет это же самостоятельно.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.bookId, super.key});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(bookId));
    final isOwned = (ref.watch(libraryProvider).valueOrNull ?? const [])
        .any((entry) => entry.book.id == bookId);
    final theme = Theme.of(context);

    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Не удалось загрузить отзывы: $error'),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Отзывов пока нет.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final review in state.reviews) _ReviewTile(review: review),
          if (state.hasMore)
            Center(
              child: state.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () => ref.read(reviewsProvider(bookId).notifier).loadMore(),
                      child: const Text('Показать ещё'),
                    ),
            ),
          const SizedBox(height: 16),
          if (isOwned)
            _ReviewForm(
              key: ValueKey('review_form_${state.myReview?.id}'),
              bookId: bookId,
              existing: state.myReview,
              isSubmitting: state.isSubmitting,
            )
          else
            Text(
              'Оставить отзыв можно после покупки книги.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewAvatar(userName: review.userName, avatarUrl: review.userAvatar),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    _StarDisplay(rating: review.rating),
                  ],
                ),
              ),
              Text(formatOrderDate(review.createdAt), style: theme.textTheme.bodySmall),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.text),
          ],
        ],
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({required this.userName, required this.avatarUrl});

  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    if (avatarUrl == null) {
      return CircleAvatar(radius: 16, child: Text(initial));
    }
    // `Image.network` + `errorBuilder`, а не `CircleAvatar.backgroundImage` —
    // у последнего нет декларативного фолбэка на ошибку загрузки, только
    // `onBackgroundImageError` (нужен State), см. тот же приём для обложки
    // книги в book_detail_screen.dart.
    return ClipOval(
      child: SizedBox(
        width: 32,
        height: 32,
        child: Image.network(
          avatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => CircleAvatar(radius: 16, child: Text(initial)),
        ),
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber[700],
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.bookId,
    required this.existing,
    required this.isSubmitting,
    super.key,
  });

  final int bookId;
  final Review? existing;
  final bool isSubmitting;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  static const _minTextLength = 10;
  static const _maxTextLength = 2000;

  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _textController = TextEditingController(
    text: widget.existing?.text ?? '',
  );

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите оценку от 1 до 5 звёзд')),
      );
      return;
    }
    final text = _textController.text.trim();
    if (text.isNotEmpty && text.length < _minTextLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Текст отзыва должен быть не короче $_minTextLength символов')),
      );
      return;
    }
    try {
      await ref.read(reviewsProvider(widget.bookId).notifier).submit(rating: _rating, text: text);
      // Средний рейтинг в шапке карточки книги считается на бэкенде по
      // отзывам динамически (без хранимого поля) — здесь просто просим
      // клиент перечитать карточку, чтобы увидеть свежее значение.
      ref.invalidate(bookDetailProvider(widget.bookId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отзыв сохранён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить отзыв?'),
        content: const Text('Отзыв будет удалён без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(reviewsProvider(widget.bookId).notifier).delete();
      ref.invalidate(bookDetailProvider(widget.bookId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing == null ? 'Оставить отзыв' : 'Ваш отзыв',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              onPressed: widget.isSubmitting ? null : () => setState(() => _rating = starIndex),
              icon: Icon(
                starIndex <= _rating ? Icons.star : Icons.star_border,
                color: Colors.amber[700],
              ),
            );
          }),
        ),
        TextField(
          controller: _textController,
          enabled: !widget.isSubmitting,
          maxLines: 3,
          maxLength: _maxTextLength,
          decoration: const InputDecoration(
            hintText: 'Расскажите о впечатлениях от книги (необязательно, от 10 символов)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: widget.isSubmitting ? null : _submit,
                child: Text(widget.existing == null ? 'Отправить' : 'Сохранить'),
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.isSubmitting ? null : _delete,
                child: const Text('Удалить'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
