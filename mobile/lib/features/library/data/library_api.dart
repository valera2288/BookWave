import 'package:dio/dio.dart';

import '../domain/library_entry.dart';
import 'library_exception.dart';

class LibraryApi {
  LibraryApi(this._dio);

  final Dio _dio;

  Future<LibraryPage> fetchLibrary() async {
    try {
      final response = await _dio.get('/library/');
      return LibraryPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw LibraryException.fromDioError(e);
    }
  }

  Future<LibraryEntry> fetchEntry(int bookId) async {
    try {
      final response = await _dio.get('/library/$bookId/');
      return LibraryEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw LibraryException.fromDioError(e);
    }
  }

  /// `updatedAt` — метка времени с устройства (last-write-wins на сервере),
  /// не серверное «сейчас» (ТЗ: конфликт прогресса разрешается по более
  /// поздней отметке времени сохранения).
  Future<LibraryEntry> updateProgress({
    required int bookId,
    required int progress,
    required DateTime updatedAt,
  }) async {
    try {
      final response = await _dio.patch(
        '/library/$bookId/',
        data: {
          'progress': progress,
          'progress_updated_at': updatedAt.toUtc().toIso8601String(),
        },
      );
      return LibraryEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw LibraryException.fromDioError(e);
    }
  }

  Future<void> removeFromLibrary(int bookId) async {
    try {
      await _dio.delete('/library/$bookId/');
    } on DioException catch (e) {
      throw LibraryException.fromDioError(e);
    }
  }
}
