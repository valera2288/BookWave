import '../../catalog/domain/book_summary.dart';

/// Запись «Моей библиотеки» — то, что отдаёт `LibraryEntrySerializer`.
class LibraryEntry {
  const LibraryEntry({
    required this.book,
    required this.availableFormats,
    required this.progress,
    required this.progressUpdatedAt,
    required this.addedAt,
  });

  final BookSummary book;
  final List<String> availableFormats;
  final int progress;
  final DateTime? progressUpdatedAt;
  final DateTime addedAt;

  /// Приоритет EPUB — он обязателен у каждой книги и для него полная
  /// функциональность читалки (ТЗ).
  String get preferredFormat =>
      availableFormats.contains('epub') ? 'epub' : availableFormats.first;

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
        book: BookSummary.fromJson(json['book'] as Map<String, dynamic>),
        availableFormats: (json['available_formats'] as List).cast<String>(),
        progress: json['progress'] as int,
        progressUpdatedAt: json['progress_updated_at'] == null
            ? null
            : DateTime.parse(json['progress_updated_at'] as String),
        addedAt: DateTime.parse(json['added_at'] as String),
      );
}

class LibraryPage {
  const LibraryPage({required this.entries});

  final List<LibraryEntry> entries;

  factory LibraryPage.fromJson(Map<String, dynamic> json) => LibraryPage(
        entries: (json['results'] as List)
            .map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
