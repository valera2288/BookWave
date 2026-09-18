/// Отзыв о книге — то, что отдаёт `ReviewSerializer`. `isMine` позволяет
/// показать кнопки редактирования/удаления прямо в списке под карточкой.
class Review {
  const Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.text,
    required this.isMine,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String text;
  final bool isMine;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        userName: json['user_name'] as String,
        userAvatar: json['user_avatar'] as String?,
        rating: json['rating'] as int,
        text: json['text'] as String? ?? '',
        isMine: json['is_mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class ReviewPage {
  const ReviewPage({required this.reviews, required this.hasMore});

  final List<Review> reviews;
  final bool hasMore;

  factory ReviewPage.fromJson(Map<String, dynamic> json) => ReviewPage(
        reviews: (json['results'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['next'] != null,
      );
}
