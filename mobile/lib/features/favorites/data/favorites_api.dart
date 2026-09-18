import 'package:dio/dio.dart';

import '../../catalog/domain/book_summary.dart';
import 'favorites_exception.dart';

class FavoritesApi {
  FavoritesApi(this._dio);

  final Dio _dio;

  Future<Set<int>> fetchFavoriteBookIds() async {
    try {
      final response = await _dio.get('/favorites/');
      return (response.data as List)
          .map((e) => ((e as Map<String, dynamic>)['book'] as Map<String, dynamic>)['id'] as int)
          .toSet();
    } on DioException catch (e) {
      throw FavoritesException.fromDioError(e);
    }
  }

  /// Полный список избранного (ТЗ: «Список избранных книг доступен в
  /// профиле пользователя в виде отдельного экрана») — тот же эндпоинт,
  /// что и `fetchFavoriteBookIds`, но с полными карточками книг.
  Future<List<BookSummary>> fetchFavorites() async {
    try {
      final response = await _dio.get('/favorites/');
      return (response.data as List)
          .map((e) => BookSummary.fromJson((e as Map<String, dynamic>)['book'] as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw FavoritesException.fromDioError(e);
    }
  }

  Future<void> addFavorite(int bookId) async {
    try {
      await _dio.post('/favorites/', data: {'book_id': bookId});
    } on DioException catch (e) {
      throw FavoritesException.fromDioError(e);
    }
  }

  Future<void> removeFavorite(int bookId) async {
    try {
      await _dio.delete('/favorites/$bookId/');
    } on DioException catch (e) {
      throw FavoritesException.fromDioError(e);
    }
  }
}
