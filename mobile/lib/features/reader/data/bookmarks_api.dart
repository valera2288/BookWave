import 'package:dio/dio.dart';

import '../domain/reader_bookmark.dart';
import 'bookmarks_exception.dart';

class BookmarksApi {
  BookmarksApi(this._dio);

  final Dio _dio;

  Future<List<ReaderBookmark>> fetchBookmarks(int bookId) async {
    try {
      final response = await _dio.get('/bookmarks/', queryParameters: {'book_id': bookId});
      return (response.data as List)
          .map((e) => ReaderBookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw BookmarksException.fromDioError(e);
    }
  }

  Future<ReaderBookmark> addBookmark({required int bookId, required String position}) async {
    try {
      final response = await _dio.post(
        '/bookmarks/',
        data: {'book_id': bookId, 'position': position},
      );
      return ReaderBookmark.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw BookmarksException.fromDioError(e);
    }
  }

  Future<void> removeBookmark(int id) async {
    try {
      await _dio.delete('/bookmarks/$id/');
    } on DioException catch (e) {
      throw BookmarksException.fromDioError(e);
    }
  }
}
