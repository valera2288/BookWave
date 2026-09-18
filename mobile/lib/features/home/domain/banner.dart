class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.image,
    required this.linkBook,
    required this.linkUrl,
  });

  final int id;
  final String image;
  final int? linkBook;
  final String linkUrl;

  factory HomeBanner.fromJson(Map<String, dynamic> json) => HomeBanner(
        id: json['id'] as int,
        image: json['image'] as String,
        linkBook: json['link_book'] as int?,
        linkUrl: json['link_url'] as String? ?? '',
      );
}
