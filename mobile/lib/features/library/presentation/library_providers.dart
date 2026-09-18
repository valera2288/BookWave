import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/library_entry.dart';

final libraryProvider = FutureProvider<List<LibraryEntry>>(
  (ref) async => (await ref.watch(libraryApiProvider).fetchLibrary()).entries,
);
