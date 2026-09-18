import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/reader_settings.dart';

class ReaderSettingsController extends AsyncNotifier<ReaderSettings> {
  @override
  Future<ReaderSettings> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return ReaderSettings(
      fontSizeIndex: prefs.readerFontSizeIndex,
      theme: ReaderThemeMode.fromStorage(prefs.readerTheme),
      continuousScroll: prefs.readerContinuousScroll,
    );
  }

  Future<void> setFontSizeIndex(int index) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(fontSizeIndex: index));
    await (await ref.read(appPreferencesProvider.future)).setReaderFontSizeIndex(index);
  }

  Future<void> setTheme(ReaderThemeMode theme) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(theme: theme));
    await (await ref.read(appPreferencesProvider.future)).setReaderTheme(theme.storageValue);
  }

  Future<void> setContinuousScroll(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(continuousScroll: value));
    await (await ref.read(appPreferencesProvider.future)).setReaderContinuousScroll(value);
  }
}

final readerSettingsProvider = AsyncNotifierProvider<ReaderSettingsController, ReaderSettings>(
  ReaderSettingsController.new,
);
