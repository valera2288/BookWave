import 'package:flutter/widgets.dart';

/// Текущая локаль приложения — обновляется из `BookWaveApp.build()`
/// (единственное место, которое реально знает язык профиля). Нужна там,
/// где нет `BuildContext` — например, дефолтные сообщения в `*_exception.dart`
/// при сетевой ошибке без ответа сервера.
Locale currentAppLocale = const Locale('ru');
