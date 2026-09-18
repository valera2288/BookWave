import 'author.dart';

/// Карточка книги в сетке каталога/рекомендаций — то, что отдаёт
/// `BookListSerializer` на бэкенде.
class BookSummary {
  const BookSummary({
    required this.id,
    required this.title,
    required this.authors,
    required this.cover,
    required this.price,
    required this.averageRating,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final List<Author> authors;
  final String? cover;
  final double price;
  final double? averageRating;
  final int ratingCount;

  factory BookSummary.fromJson(Map<String, dynamic> json) => BookSummary(
        id: json['id'] as int,
        title: json['title'] as String,
        authors: (json['authors'] as List)
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList(),
        cover: json['cover'] as String?,
        price: double.parse(json['price'].toString()),
        averageRating: json['average_rating'] == null
            ? null
            : double.parse(json['average_rating'].toString()),
        ratingCount: json['rating_count'] as int,
      );
}
