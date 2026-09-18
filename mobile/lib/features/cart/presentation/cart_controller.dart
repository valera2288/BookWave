import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/cart.dart';

class CartController extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() {
    return ref.read(cartApiProvider).fetchCart();
  }

  /// Возвращает false, если книга уже была в корзине (ничего не добавлено).
  Future<bool> addBook(int bookId) async {
    final previous = state;
    state = const AsyncLoading<Cart>().copyWithPrevious(previous);
    try {
      final (cart, added) = await ref.read(cartApiProvider).addItem(bookId);
      state = AsyncData(cart);
      return added;
    } catch (e, stackTrace) {
      state = AsyncError<Cart>(e, stackTrace).copyWithPrevious(previous);
      rethrow;
    }
  }

  Future<void> removeItem(int bookId) async {
    final previous = state;
    state = const AsyncLoading<Cart>().copyWithPrevious(previous);
    try {
      await ref.read(cartApiProvider).removeItem(bookId);
      state = AsyncData(await ref.read(cartApiProvider).fetchCart());
    } catch (e, stackTrace) {
      state = AsyncError<Cart>(e, stackTrace).copyWithPrevious(previous);
      rethrow;
    }
  }
}

final cartControllerProvider = AsyncNotifierProvider<CartController, Cart>(CartController.new);
