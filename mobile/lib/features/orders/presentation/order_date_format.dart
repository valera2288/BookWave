const _months = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

/// Без пакета `intl` (в проекте его нет) — простое ручное форматирование
/// даты заказа, используется и в истории заказов, и в деталях заказа.
String formatOrderDate(DateTime date) {
  final local = date.toLocal();
  final time = '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '${local.day} ${_months[local.month - 1]} ${local.year}, $time';
}
