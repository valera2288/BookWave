import '../../../l10n/app_localizations.dart';

/// Настройки читалки (ТЗ: шрифт — не менее 5 градаций, тема — светлая/
/// тёмная/сепия, постраничная/непрерывная навигация на выбор). Хранятся
/// локально на устройстве, не синхронизируются с сервером — это личные
/// настройки чтения, а не данные книги.
class ReaderSettings {
  const ReaderSettings({
    required this.fontSizeIndex,
    required this.theme,
    required this.continuousScroll,
  });

  final int fontSizeIndex;
  final ReaderThemeMode theme;
  final bool continuousScroll;

  static const fontSizes = [14.0, 16.0, 18.0, 20.0, 24.0, 28.0];

  double get fontSize => fontSizes[fontSizeIndex];

  ReaderSettings copyWith({
    int? fontSizeIndex,
    ReaderThemeMode? theme,
    bool? continuousScroll,
  }) =>
      ReaderSettings(
        fontSizeIndex: fontSizeIndex ?? this.fontSizeIndex,
        theme: theme ?? this.theme,
        continuousScroll: continuousScroll ?? this.continuousScroll,
      );
}

enum ReaderThemeMode {
  light('light'),
  dark('dark'),
  sepia('sepia');

  const ReaderThemeMode(this.storageValue);

  final String storageValue;

  String label(AppLocalizations l10n) => switch (this) {
        ReaderThemeMode.light => l10n.readerThemeLight,
        ReaderThemeMode.dark => l10n.readerThemeDark,
        ReaderThemeMode.sepia => l10n.readerThemeSepia,
      };

  factory ReaderThemeMode.fromStorage(String value) => ReaderThemeMode.values.firstWhere(
        (mode) => mode.storageValue == value,
        orElse: () => ReaderThemeMode.light,
      );
}
