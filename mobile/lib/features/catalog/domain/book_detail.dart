import 'author.dart';
import 'genre.dart';

/// Карточка книги — то, что отдаёт `BookDetailSerializer`. Файлов книги
/// здесь нет: их отдаёт только защищённый эндпоинт библиотеки (Phase 6).
class BookDetail {
  const BookDetail({
    required this.id,
    required this.title,
    required this.authors,
    required this.genres,
    required this.language,
    required this.publisher,
    required this.publicationYear,
    required this.pageCount,
    required this.isbn,
    required this.price,
    required this.averageRating,
    required this.ratingCount,
    required this.description,
    required this.cover,
    required this.availableFormats,
  });

  final int id;
  final String title;
  final List<Author> authors;
  final List<Genre> genres;
  final String language;
  final String publisher;
  final int? publicationYear;
  final int? pageCount;
  final String isbn;
  final double price;
  final double? averageRating;
  final int ratingCount;
  final String description;
  final String? cover;
  final List<String> availableFormats;

  /// EPUB обязателен для каждой книги, поэтому приоритетен для читалки
  /// (ТЗ: «Основным форматом... является EPUB»).
  String get preferredFormat =>
      availableFormats.contains('epub') ? 'epub' : availableFormats.first;

  factory BookDetail.fromJson(Map<String, dynamic> json) => BookDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        authors: (json['authors'] as List)
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList(),
        genres: (json['genres'] as List)
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList(),
        language: json['language'] as String,
        publisher: json['publisher'] as String? ?? '',
        publicationYear: json['publication_year'] as int?,
        pageCount: json['page_count'] as int?,
        isbn: json['isbn'] as String,
        price: double.parse(json['price'].toString()),
        averageRating: json['average_rating'] == null
            ? null
            : double.parse(json['average_rating'].toString()),
        ratingCount: json['rating_count'] as int,
        description: json['description'] as String? ?? '',
        cover: json['cover'] as String?,
        availableFormats: (json['available_formats'] as List).cast<String>(),
      );
}
