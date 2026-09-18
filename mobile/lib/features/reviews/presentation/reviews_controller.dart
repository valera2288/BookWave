import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/review.dart';

class ReviewsState {
  const ReviewsState({
    this.reviews = const [],
    this.myReview,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
  });

  final List<Review> reviews;
  final Review? myReview;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSubmitting;

  ReviewsState copyWith({
    List<Review>? reviews,
    Review? Function()? myReview,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSubmitting,
  }) {
    return ReviewsState(
      reviews: reviews ?? this.reviews,
      myReview: myReview != null ? myReview() : this.myReview,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Отзывы одной книги: публичный список (постранично, ТЗ — «с возможностью
/// пролистывания») плюс отдельно отзыв текущего пользователя, который
/// определяет, показывать форму «оставить отзыв» или «редактировать свой».
class ReviewsController extends FamilyAsyncNotifier<ReviewsState, int> {
  int _page = 1;

  @override
  Future<ReviewsState> build(int bookId) async {
    _page = 1;
    final api = ref.read(reviewsApiProvider);
    final page = await api.fetchReviews(bookId: bookId, page: 1);
    final mine = await api.fetchMyReview(bookId);
    return ReviewsState(reviews: page.reviews, myReview: mine, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref.read(reviewsApiProvider).fetchReviews(bookId: arg, page: _page + 1);
      _page += 1;
      state = AsyncData(
        current.copyWith(
          reviews: [...current.reviews, ...page.reviews],
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  Future<void> submit({required int rating, required String text}) async {
    final current = state.valueOrNull ?? const ReviewsState();
    state = AsyncData(current.copyWith(isSubmitting: true));
    final api = ref.read(reviewsApiProvider);
    try {
      final wasNew = current.myReview == null;
      final review = wasNew
          ? await api.createReview(bookId: arg, rating: rating, text: text)
          : await api.updateReview(bookId: arg, rating: rating, text: text);
      await _refreshFirstPage(myReview: review);
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> delete() async {
    final current = state.valueOrNull;
    if (current == null || current.myReview == null) return;
    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(reviewsApiProvider).deleteReview(arg);
      await _refreshFirstPage(myReview: null);
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  /// После создания/изменения/удаления собственного отзыва порядок на
  /// сервере сдвигается на один элемент — точечно патчить локальный список
  /// небезопасно: следующий `loadMore()` со старым `_page` может задвоить
  /// или пропустить элемент (сдвиг границы страницы на сервере). Проще и
  /// надёжнее перечитать первую страницу заново.
  Future<void> _refreshFirstPage({required Review? myReview}) async {
    _page = 1;
    final page = await ref.read(reviewsApiProvider).fetchReviews(bookId: arg, page: 1);
    state = AsyncData(
      ReviewsState(reviews: page.reviews, myReview: myReview, hasMore: page.hasMore),
    );
  }
}

final reviewsProvider = AsyncNotifierProvider.family<ReviewsController, ReviewsState, int>(
  ReviewsController.new,
);
