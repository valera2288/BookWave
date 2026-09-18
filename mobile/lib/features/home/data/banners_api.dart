import 'package:dio/dio.dart';

import '../../catalog/data/catalog_exception.dart';
import '../domain/banner.dart';

class BannersApi {
  BannersApi(this._dio);

  final Dio _dio;

  Future<List<HomeBanner>> fetchActiveBanners() async {
    try {
      final response = await _dio.get('/banners/');
      return (response.data as List)
          .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CatalogException.fromDioError(e);
    }
  }
}
