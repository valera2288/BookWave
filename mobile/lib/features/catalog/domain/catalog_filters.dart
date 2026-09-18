import 'catalog_sort.dart';

/// Состояние поиска/фильтров/сортировки каталога. Иммутабельно — экран
/// фильтров редактирует копию и применяет её через `copyWith`.
class CatalogFilters {
  const CatalogFilters({
    this.search = '',
    this.genreIds = const {},
    this.language,
    this.priceMin,
    this.priceMax,
    this.ratingMin,
    this.sort = CatalogSort.defaultOrder,
  });

  final String search;
  final Set<int> genreIds;
  final String? language;
  final double? priceMin;
  final double? priceMax;
  final int? ratingMin;
  final CatalogSort sort;

  bool get hasActiveFilters =>
      genreIds.isNotEmpty ||
      language != null ||
      priceMin != null ||
      priceMax != null ||
      ratingMin != null;

  CatalogFilters copyWith({
    String? search,
    Set<int>? genreIds,
    String? Function()? language,
    double? Function()? priceMin,
    double? Function()? priceMax,
    int? Function()? ratingMin,
    CatalogSort? sort,
  }) {
    return CatalogFilters(
      search: search ?? this.search,
      genreIds: genreIds ?? this.genreIds,
      language: language != null ? language() : this.language,
      priceMin: priceMin != null ? priceMin() : this.priceMin,
      priceMax: priceMax != null ? priceMax() : this.priceMax,
      ratingMin: ratingMin != null ? ratingMin() : this.ratingMin,
      sort: sort ?? this.sort,
    );
  }

  CatalogFilters clearFilters() => CatalogFilters(search: search, sort: sort);

  Map<String, dynamic> toQueryParameters() {
    return {
      if (search.trim().length >= 2) 'search': search.trim(),
      if (genreIds.isNotEmpty) 'genre': genreIds.join(','),
      if (language != null) 'language': language,
      if (priceMin != null) 'price_min': priceMin.toString(),
      if (priceMax != null) 'price_max': priceMax.toString(),
      if (ratingMin != null) 'rating_min': ratingMin.toString(),
      'sort': sort.apiValue,
    };
  }
}
