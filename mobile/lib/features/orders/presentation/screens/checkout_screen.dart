import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../../cart/domain/cart.dart';
import '../../../cart/presentation/cart_controller.dart';
import '../../../home/presentation/home_providers.dart';
import '../../../library/presentation/library_providers.dart';
import '../../../promo/domain/promo_preview.dart';
import '../../../promo/presentation/promo_controller.dart';
import '../../data/orders_exception.dart';
import '../orders_providers.dart';
import 'order_success_screen.dart';

/// Экран «Оформление заказа» из ТЗ: список книг и сумма, блок оплаты
/// (тестовые платёжные данные, имитация успеха/отказа), кнопка «Оплатить».
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({required this.cart, required this.promo, super.key});

  final Cart cart;
  final PromoPreview? promo;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _cardController = TextEditingController(text: '4242 4242 4242 4242');
  bool _submitting = false;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  bool get _promoApplies => widget.promo != null && widget.promo!.subtotal == widget.cart.total;

  double get _total => _promoApplies ? widget.promo!.total : widget.cart.total;

  Future<void> _pay() async {
    setState(() => _submitting = true);
    try {
      final order = await ref.read(ordersApiProvider).checkout(
            cardNumber: _cardController.text,
            promoCode: _promoApplies ? widget.promo!.code : null,
          );
      ref.invalidate(cartControllerProvider);
      // Заказ пополняет и библиотеку, и историю заказов — обе кешируются
      // в глобальных FutureProvider'ах, без явной инвалидации экраны
      // показывали бы старые данные до ручного pull-to-refresh.
      ref.invalidate(libraryProvider);
      ref.invalidate(orderHistoryProvider);
      // ТЗ: «Рекомендуем» не должен предлагать книги, уже купленные
      // пользователем — без инвалидации купленная книга оставалась бы в
      // подборке до следующего холодного старта.
      ref.invalidate(recommendationsProvider);
      ref.read(promoControllerProvider.notifier).clear();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        );
      }
    } on OrdersException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.checkoutYourOrder, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in widget.cart.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.book.title, overflow: TextOverflow.ellipsis)),
                    Text('${item.book.price.toStringAsFixed(0)} ₽'),
                  ],
                ),
              ),
            const Divider(height: 32),
            AmountRow(label: l10n.cartSubtotal, value: widget.cart.total),
            if (_promoApplies)
              AmountRow(label: l10n.cartPromoDiscount, value: -widget.promo!.discount),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.checkoutTotalToPay, style: theme.textTheme.titleMedium),
                Text(
                  '${_total.toStringAsFixed(0)} ₽',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.checkoutPayment, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.checkoutPaymentHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.checkoutCardNumber,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _pay,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.checkoutPayButton),
            ),
          ],
        ),
      ),
    );
  }
}
