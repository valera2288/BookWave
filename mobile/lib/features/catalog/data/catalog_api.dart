import 'package:dio/dio.dart';

import '../domain/book_detail.dart';
import '../domain/catalog_filters.dart';
import '../domain/catalog_page.dart';
import '../domain/genre.dart';
import 'catalog_exception.dart';

class CatalogApi {
  CatalogApi(this._dio);

  final Dio _dio;

  Future<CatalogPage> fetchBooks({required CatalogFilters filters, required int page}) async {
    try {
      final response = await _dio.get(
        '/catalog/books/',
        queryParameters: {...filters.toQueryParameters(), 'page': page},
      );
      return CatalogPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }

  Future<BookDetail> fetchBook(int id) async {
    try {
      final response = await _dio.get('/catalog/books/$id/');
      return BookDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }

  Future<List<Genre>> fetchGenres() async {
    try {
      final response = await _dio.get('/catalog/genres/');
      return (response.data as List)
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }

  Future<List<String>> fetchLanguages() async {
    try {
      final response = await _dio.get('/catalog/languages/');
      return (response.data as List).cast<String>();
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }

  Future<CatalogPage> fetchRecommendations() async {
    try {
      final response = await _dio.get('/catalog/recommendations/');
      final results = response.data as List;
      // У рекомендаций нет пагинации на бэкенде — оборачиваем в тот же
      // формат, что и обычный список, чтобы переиспользовать CatalogPage.
      return CatalogPage.fromJson({
        'results': results,
        'next': null,
        'count': results.length,
      });
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }

  Future<CatalogPage> fetchTopSellers() async {
    try {
      final response = await _dio.get('/catalog/top-sellers/');
      final results = response.data as List;
      // Как и у рекомендаций, пагинации нет — оборачиваем в CatalogPage.
      return CatalogPage.fromJson({
        'results': results,
        'next': null,
        'count': results.length,
      });
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }
}
