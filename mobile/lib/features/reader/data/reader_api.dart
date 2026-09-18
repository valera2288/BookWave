import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'reader_exception.dart';

class ReaderApi {
  ReaderApi(this._dio);

  final Dio _dio;

  /// Скачивает файл книги — полный, если куплена, фрагмент, если нет (это
  /// решает сервер по владению, см. `apps/files/views.py`), и сохраняет во
  /// временный локальный файл: вьюерам (epub.js/Syncfusion) нужен обычный
  /// файл на диске, не поток с заголовком авторизации.
  Future<File> downloadBookFile({required int bookId, required String format}) async {
    try {
      final response = await _dio.get<List<int>>(
        '/files/books/$bookId/$format/',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bookwave_book_$bookId.$format');
      await file.writeAsBytes(response.data!, flush: true);
      return file;
    } on DioException catch (e) {
      throw ReaderException.fromDioError(e);
    }
  }
}
