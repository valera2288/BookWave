import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/book_summary.dart';
import '../../catalog/domain/catalog_filters.dart';
import '../../catalog/domain/catalog_sort.dart';
import '../domain/banner.dart';

final activeBannersProvider = FutureProvider<List<HomeBanner>>(
  (ref) => ref.watch(bannersApiProvider).fetchActiveBanners(),
);

final recommendationsProvider = FutureProvider<List<BookSummary>>(
  (ref) async => (await ref.watch(catalogApiProvider).fetchRecommendations()).books,
);

// ТЗ: блок «Новинки» на главной.
final newestBooksProvider = FutureProvider<List<BookSummary>>(
  (ref) async {
    final page = await ref.watch(catalogApiProvider).fetchBooks(
          filters: const CatalogFilters(sort: CatalogSort.newest),
          page: 1,
        );
    return page.books.take(10).toList();
  },
);

// ТЗ: блок «Топ продаж» на главной — данные заказов появились в Phase 5.
final topSellersProvider = FutureProvider<List<BookSummary>>(
  (ref) async => (await ref.watch(catalogApiProvider).fetchTopSellers()).books,
);
