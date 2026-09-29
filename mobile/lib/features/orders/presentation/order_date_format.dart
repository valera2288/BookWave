import 'package:intl/intl.dart';

/// Дата заказа, используется и в истории заказов, и в деталях заказа —
/// формат зависит от языка интерфейса (ТЗ: выбор языка в «Настройках»).
String formatOrderDate(DateTime date, String locale) {
  return DateFormat('d MMMM yyyy, HH:mm', locale).format(date.toLocal());
}
