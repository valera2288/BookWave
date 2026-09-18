/// Значения соответствуют `SORT_OPTIONS` в `apps/catalog/views.py`.
enum CatalogSort {
  defaultOrder('default', 'По умолчанию'),
  cheapFirst('cheap_first', 'Сначала дешёвые'),
  expensiveFirst('expensive_first', 'Сначала дорогие'),
  rating('rating', 'По рейтингу'),
  newest('newest', 'Сначала новинки');

  const CatalogSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
