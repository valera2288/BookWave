/// Закладка в тексте книги (ТЗ: «добавление и удаление закладок на текущей
/// странице»). `position` — CFI-строка epub.js, непрозрачна для клиента
/// так же, как и для бэкенда — используется только для перехода обратно.
class ReaderBookmark {
  const ReaderBookmark({required this.id, required this.position, required this.createdAt});

  final int id;
  final String position;
  final DateTime createdAt;

  factory ReaderBookmark.fromJson(Map<String, dynamic> json) => ReaderBookmark(
        id: json['id'] as int,
        position: json['position'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
