// `Book.language` — свободный текст на бэкенде (нет фиксированного списка
// значений, см. `LanguageListView`), но каталог фактически использует
// ISO 639-1 коды ("ru"/"en") — тот же набор, что и в мобильном приложении
// (`mobile/lib/features/catalog/presentation/language_label.dart`).

export const LANGUAGE_OPTIONS: { value: string; label: string }[] = [
  { value: "ru", label: "Русский" },
  { value: "en", label: "English" },
];

export function languageLabel(code: string): string {
  return LANGUAGE_OPTIONS.find((o) => o.value === code.toLowerCase())?.label ?? code;
}
