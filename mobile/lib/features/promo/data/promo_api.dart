import 'package:dio/dio.dart';

import '../domain/promo_preview.dart';
import 'promo_exception.dart';

class PromoApi {
  PromoApi(this._dio);

  final Dio _dio;

  Future<PromoPreview> validate(String code) async {
    try {
      final response = await _dio.post('/promo/validate/', data: {'code': code});
      return PromoPreview.fromJson(code, response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PromoException.fromDioError(e);
    }
  }
}
