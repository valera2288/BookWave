import 'book_summary.dart';

class CatalogPage {
  const CatalogPage({required this.books, required this.hasMore, required this.totalCount});

  final List<BookSummary> books;
  final bool hasMore;
  final int totalCount;

  factory CatalogPage.fromJson(Map<String, dynamic> json) => CatalogPage(
        books: (json['results'] as List)
            .map((e) => BookSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['next'] != null,
        totalCount: json['count'] as int,
      );
}
