import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/genre.dart';

/// Справочники для экрана фильтров — жанры и реально встречающиеся языки.
final genresProvider = FutureProvider<List<Genre>>(
  (ref) => ref.watch(catalogApiProvider).fetchGenres(),
);

final languagesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogApiProvider).fetchLanguages(),
);
