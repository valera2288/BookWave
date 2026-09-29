import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/genre.dart';

/// Блок «Жанры» в виде плиток с переходом в отфильтрованный каталог (ТЗ).
class GenreTiles extends StatelessWidget {
  const GenreTiles({required this.genres, required this.onGenreTap, super.key});

  final List<Genre> genres;
  final ValueChanged<Genre> onGenreTap;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(AppLocalizations.of(context)!.homeSectionGenres, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in genres)
                ActionChip(
                  label: Text(genre.name),
                  onPressed: () => onGenreTap(genre),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
