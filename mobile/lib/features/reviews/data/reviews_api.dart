import 'package:dio/dio.dart';

import '../domain/review.dart';
import 'reviews_exception.dart';

class ReviewsApi {
  ReviewsApi(this._dio);

  final Dio _dio;

  Future<ReviewPage> fetchReviews({required int bookId, required int page}) async {
    try {
      final response = await _dio.get(
        '/reviews/book/$bookId/',
        queryParameters: {'page': page},
      );
      return ReviewPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ReviewsException.fromDioError(e);
    }
  }

  /// `null`, если пользователь ещё не оставлял отзыв на эту книгу.
  Future<Review?> fetchMyReview(int bookId) async {
    try {
      final response = await _dio.get('/reviews/book/$bookId/mine/');
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ReviewsException.fromDioError(e);
    }
  }

  Future<Review> createReview({
    required int bookId,
    required int rating,
    required String text,
  }) async {
    try {
      final response = await _dio.post(
        '/reviews/book/$bookId/mine/',
        data: {'rating': rating, 'text': text},
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ReviewsException.fromDioError(e);
    }
  }

  Future<Review> updateReview({
    required int bookId,
    required int rating,
    required String text,
  }) async {
    try {
      final response = await _dio.patch(
        '/reviews/book/$bookId/mine/',
        data: {'rating': rating, 'text': text},
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ReviewsException.fromDioError(e);
    }
  }

  Future<void> deleteReview(int bookId) async {
    try {
      await _dio.delete('/reviews/book/$bookId/mine/');
    } on DioException catch (e) {
      throw ReviewsException.fromDioError(e);
    }
  }
}
