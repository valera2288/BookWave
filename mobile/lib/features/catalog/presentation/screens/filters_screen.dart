import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/catalog_filters.dart';
import '../catalog_reference_providers.dart';
import '../language_label.dart';

const _priceSliderMax = 10000.0;

/// Экран «Фильтры» из ТЗ: жанр (чекбоксы), диапазон цены (ползунок), язык,
/// рейтинг, кнопки «Сбросить»/«Применить». Возвращает новый [CatalogFilters]
/// через `Navigator.pop`, ничего не применяет сам — решает вызывающий экран.
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({required this.initialFilters, super.key});

  final CatalogFilters initialFilters;

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  late Set<int> _genreIds = {...widget.initialFilters.genreIds};
  late String? _language = widget.initialFilters.language;
  late RangeValues _priceRange = RangeValues(
    widget.initialFilters.priceMin ?? 0,
    widget.initialFilters.priceMax ?? _priceSliderMax,
  );
  late int? _ratingMin = widget.initialFilters.ratingMin;

  void _reset() {
    setState(() {
      _genreIds = {};
      _language = null;
      _priceRange = const RangeValues(0, _priceSliderMax);
      _ratingMin = null;
    });
  }

  void _apply() {
    final filters = widget.initialFilters.copyWith(
      genreIds: _genreIds,
      language: () => _language,
      priceMin: () => _priceRange.start > 0 ? _priceRange.start : null,
      priceMax: () => _priceRange.end < _priceSliderMax ? _priceRange.end : null,
      ratingMin: () => _ratingMin,
    );
    Navigator.of(context).pop(filters);
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    final languagesAsync = ref.watch(languagesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogFiltersTooltip),
        actions: [
          TextButton(onPressed: _reset, child: Text(l10n.filtersReset)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.filtersGenreLabel, style: Theme.of(context).textTheme.titleMedium),
          genresAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(l10n.filtersGenresLoadError),
            // ТЗ: выбор жанра — чекбоксы, не чипы.
            data: (genres) => Column(
              children: [
                for (final genre in genres)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(genre.name),
                    value: _genreIds.contains(genre.id),
                    onChanged: (selected) => setState(() {
                      if (selected ?? false) {
                        _genreIds.add(genre.id);
                      } else {
                        _genreIds.remove(genre.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.filtersPriceLabel, style: Theme.of(context).textTheme.titleMedium),
          RangeSlider(
            min: 0,
            max: _priceSliderMax,
            divisions: 100,
            labels: RangeLabels(
              _priceRange.start.toStringAsFixed(0),
              _priceRange.end.toStringAsFixed(0),
            ),
            values: _priceRange,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_priceRange.start.toStringAsFixed(0)} ₽'),
              Text('${_priceRange.end.toStringAsFixed(0)} ₽'),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.filtersLanguageLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          languagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(l10n.filtersLanguagesLoadError),
            data: (languages) => Wrap(
              spacing: 8,
              children: [
                for (final language in languages)
                  ChoiceChip(
                    label: Text(languageDisplayName(language, l10n)),
                    selected: _language == language,
                    onSelected: (selected) =>
                        setState(() => _language = selected ? language : null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.filtersMinRatingLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final rating in [1, 2, 3, 4, 5])
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$rating'),
                      const Icon(Icons.star, size: 16),
                      const Text('+'),
                    ],
                  ),
                  selected: _ratingMin == rating,
                  onSelected: (selected) =>
                      setState(() => _ratingMin = selected ? rating : null),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: _apply, child: Text(l10n.filtersApply)),
        ],
      ),
    );
  }
}
