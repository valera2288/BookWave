import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/book_summary.dart';
import '../domain/catalog_filters.dart';
import '../domain/catalog_sort.dart';

class CatalogState {
  const CatalogState({
    this.books = const [],
    this.filters = const CatalogFilters(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.error,
  });

  final List<BookSummary> books;
  final CatalogFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final String? error;

  CatalogState copyWith({
    List<BookSummary>? books,
    CatalogFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    String? Function()? error,
  }) {
    return CatalogState(
      books: books ?? this.books,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      error: error != null ? error() : this.error,
    );
  }
}

/// Постраничная (по 20, см. ТЗ) загрузка каталога с поиском/фильтрами/
/// сортировкой. Любое изменение search/filters/sort сбрасывает список и
/// грузит первую страницу заново — это самый простой способ не запутаться
/// в частично смешанных результатах разных запросов.
class CatalogController extends Notifier<CatalogState> {
  int _page = 1;
  int _requestId = 0;

  @override
  CatalogState build() {
    Future.microtask(_loadFirstPage);
    return const CatalogState(isLoading: true);
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    _page = 1;
    state = state.copyWith(isLoading: true, error: () => null);
    final api = ref.read(catalogApiProvider);
    try {
      final result = await api.fetchBooks(filters: state.filters, page: _page);
      if (requestId != _requestId) return; // устарел — пришёл более новый запрос
      state = state.copyWith(
        books: result.books,
        hasMore: result.hasMore,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    final requestId = _requestId;
    state = state.copyWith(isLoadingMore: true);
    final api = ref.read(catalogApiProvider);
    try {
      final result = await api.fetchBooks(filters: state.filters, page: _page + 1);
      if (requestId != _requestId) return;
      _page += 1;
      state = state.copyWith(
        books: [...state.books, ...result.books],
        hasMore: result.hasMore,
        totalCount: result.totalCount,
        isLoadingMore: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, error: () => e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(filters: state.filters.copyWith(search: value));
    _loadFirstPage();
  }

  void setSort(CatalogSort sort) {
    state = state.copyWith(filters: state.filters.copyWith(sort: sort));
    _loadFirstPage();
  }

  void applyFilters(CatalogFilters filters) {
    // search/sort остаются прежними — экран фильтров редактирует только
    // жанр/язык/цену/рейтинг.
    state = state.copyWith(
      filters: filters.copyWith(search: state.filters.search, sort: state.filters.sort),
    );
    _loadFirstPage();
  }
}

final catalogControllerProvider = NotifierProvider<CatalogController, CatalogState>(
  CatalogController.new,
);
