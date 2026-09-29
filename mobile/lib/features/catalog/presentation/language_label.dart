import '../../../l10n/app_localizations.dart';

/// `Book.language` — свободный текст на бэкенде (нет фиксированного списка
/// значений), но текущий каталог использует ISO 639-1 коды ("ru"/"en").
/// Показываем их читаемым названием; любое другое значение (например, если
/// админ ввёл язык текстом напрямую) — как есть, без падения.
String languageDisplayName(String code, AppLocalizations l10n) {
  switch (code.toLowerCase()) {
    case 'ru':
      return l10n.languageRussian;
    case 'en':
      return l10n.languageEnglish;
    default:
      return code;
  }
}
