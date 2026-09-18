import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../book_details/presentation/screens/book_detail_screen.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/book_summary.dart';
import '../../domain/catalog_filters.dart';
import '../../domain/catalog_sort.dart';
import '../catalog_controller.dart';
import '../catalog_reference_providers.dart';
import '../widgets/book_card.dart';
import 'filters_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({this.initialGenreId, super.key});

  /// Задаётся при переходе с плитки жанра на главной («переход в
  /// отфильтрованный каталог», ТЗ).
  final int? initialGenreId;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialGenreId != null) {
      Future.microtask(() {
        final current = ref.read(catalogControllerProvider).filters;
        ref.read(catalogControllerProvider.notifier).applyFilters(
              current.copyWith(genreIds: {widget.initialGenreId!}),
            );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(catalogControllerProvider.notifier).loadMore();
    }
  }

  // ТЗ: поиск с задержкой не более 500 мс после остановки ввода, минимум
  // с 2 символов (пустая строка — тоже валидна, сбрасывает поиск).
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isEmpty || value.trim().length >= 2) {
        ref.read(catalogControllerProvider.notifier).setSearch(value);
      }
    });
  }

  Future<void> _openFilters(CatalogFilters current) async {
    final result = await Navigator.of(context).push<CatalogFilters>(
      MaterialPageRoute(builder: (_) => FiltersScreen(initialFilters: current)),
    );
    if (result != null) {
      ref.read(catalogControllerProvider.notifier).applyFilters(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог'),
        actions: [
          PopupMenuButton<CatalogSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Сортировка',
            initialValue: state.filters.sort,
            onSelected: (sort) =>
                ref.read(catalogControllerProvider.notifier).setSort(sort),
            itemBuilder: (context) => [
              for (final sort in CatalogSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтры',
            onPressed: () => _openFilters(state.filters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Название, автор, ISBN',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (state.filters.hasActiveFilters) _ActiveFilterTags(filters: state.filters),
          Expanded(child: _CatalogBody(state: state, scrollController: _scrollController)),
        ],
      ),
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody({required this.state, required this.scrollController});

  final CatalogState state;
  final ScrollController scrollController;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, BookSummary book) async {
    try {
      await ref.read(favoritesControllerProvider.notifier).toggle(book.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(catalogControllerProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (state.books.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }

    final favoriteBookIds = ref.watch(favoritesControllerProvider).valueOrNull ?? const {};

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        // 0.55 переполнял карточку снизу на двухстрочных названиях (тот же
        // баг, что в BookRow на главной) — 0.5 даёт запас.
        childAspectRatio: 0.5,
      ),
      itemCount: state.books.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.books.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final book = state.books[index];
        return BookCard(
          book: book,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
          ),
          isFavorite: favoriteBookIds.contains(book.id),
          onFavoriteTap: () => _toggleFavorite(context, ref, book),
        );
      },
    );
  }
}

class _ActiveFilterTags extends ConsumerWidget {
  const _ActiveFilterTags({required this.filters});

  final CatalogFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    final genreNames = genresAsync.maybeWhen(
      data: (genres) => {for (final g in genres) g.id: g.name},
      orElse: () => <int, String>{},
    );

    void update(CatalogFilters next) =>
        ref.read(catalogControllerProvider.notifier).applyFilters(next);

    final chips = <Widget>[
      for (final genreId in filters.genreIds)
        InputChip(
          label: Text(genreNames[genreId] ?? 'Жанр'),
          onDeleted: () => update(
            filters.copyWith(genreIds: {...filters.genreIds}..remove(genreId)),
          ),
        ),
      if (filters.language != null)
        InputChip(
          label: Text(filters.language!),
          onDeleted: () => update(filters.copyWith(language: () => null)),
        ),
      if (filters.priceMin != null || filters.priceMax != null)
        InputChip(
          label: Text(
            '${filters.priceMin?.toStringAsFixed(0) ?? '0'}–'
            '${filters.priceMax?.toStringAsFixed(0) ?? '∞'} ₽',
          ),
          onDeleted: () => update(
            filters.copyWith(priceMin: () => null, priceMax: () => null),
          ),
        ),
      if (filters.ratingMin != null)
        InputChip(
          label: Text('от ${filters.ratingMin}★'),
          onDeleted: () => update(filters.copyWith(ratingMin: () => null)),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}
