import '../../../l10n/app_localizations.dart';

/// Значения соответствуют `SORT_OPTIONS` в `apps/catalog/views.py`.
enum CatalogSort {
  defaultOrder('default'),
  cheapFirst('cheap_first'),
  expensiveFirst('expensive_first'),
  rating('rating'),
  newest('newest');

  const CatalogSort(this.apiValue);

  final String apiValue;

  String label(AppLocalizations l10n) => switch (this) {
        CatalogSort.defaultOrder => l10n.catalogSortDefault,
        CatalogSort.cheapFirst => l10n.catalogSortCheapFirst,
        CatalogSort.expensiveFirst => l10n.catalogSortExpensiveFirst,
        CatalogSort.rating => l10n.catalogSortRating,
        CatalogSort.newest => l10n.catalogSortNewest,
      };
}
