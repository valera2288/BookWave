import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// Фирменный цвет BookWave — тот же, что `--accent` в админ-панели
  /// (admin-panel/src/shared/styles.css), ТЗ: единый фирменный стиль.
  static const brandColor = Color(0xFF4F46E5);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
    useMaterial3: true,
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
