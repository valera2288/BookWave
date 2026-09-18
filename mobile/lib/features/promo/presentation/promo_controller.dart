import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/promo_preview.dart';

class PromoState {
  const PromoState({this.preview, this.isLoading = false, this.error});

  final PromoPreview? preview;
  final bool isLoading;
  final String? error;

  PromoState copyWith({
    PromoPreview? Function()? preview,
    bool? isLoading,
    String? Function()? error,
  }) {
    return PromoState(
      preview: preview != null ? preview() : this.preview,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

/// Применённый промокод на экране корзины — чисто клиентское превью
/// (ТЗ 162-164), ничего не сохраняет на сервере. Реальная проверка и
/// расчёт скидки происходят заново при оформлении заказа.
class PromoController extends Notifier<PromoState> {
  @override
  PromoState build() => const PromoState();

  Future<void> apply(String code) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final preview = await ref.read(promoApiProvider).validate(code);
      state = state.copyWith(preview: () => preview, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  void clear() {
    state = const PromoState();
  }
}

final promoControllerProvider = NotifierProvider<PromoController, PromoState>(
  PromoController.new,
);
