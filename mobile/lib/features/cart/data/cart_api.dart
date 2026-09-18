import 'package:dio/dio.dart';

import '../domain/cart.dart';
import 'cart_exception.dart';

class CartApi {
  CartApi(this._dio);

  final Dio _dio;

  Future<Cart> fetchCart() async {
    try {
      final response = await _dio.get('/cart/');
      return Cart.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw CartException.fromDioError(e);
    }
  }

  /// `added` — false, если книга уже была в корзине (бэкенд отвечает 200
  /// вместо 201 и не создаёт дубликат, см. ТЗ).
  Future<(Cart cart, bool added)> addItem(int bookId) async {
    try {
      final response = await _dio.post('/cart/items/', data: {'book_id': bookId});
      final cart = Cart.fromJson(response.data as Map<String, dynamic>);
      return (cart, response.statusCode == 201);
    } on DioException catch (e) {
      throw CartException.fromDioError(e);
    }
  }

  Future<void> removeItem(int bookId) async {
    try {
      await _dio.delete('/cart/items/$bookId/');
    } on DioException catch (e) {
      throw CartException.fromDioError(e);
    }
  }
}
