import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/amount_row.dart';
import '../../../orders/presentation/screens/checkout_screen.dart';
import '../../../promo/presentation/promo_controller.dart';
import '../../domain/cart.dart';
import '../cart_controller.dart';

/// Экран «Корзина» из ТЗ: список позиций (обложка, название, цена),
/// удаление позиции, поле промокода, блок расчёта, «Оформить заказ».
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _removeItem(BuildContext context, WidgetRef ref, int bookId) async {
    try {
      await ref.read(cartControllerProvider.notifier).removeItem(bookId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openCheckout(BuildContext context, WidgetRef ref, Cart cart) {
    final promo = ref.read(promoControllerProvider).preview;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart, promo: promo)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(cartControllerProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (cart) => cart.items.isEmpty
            ? const Center(child: Text('Корзина пуста'))
            : _CartBody(
                cart: cart,
                onRemove: (bookId) => _removeItem(context, ref, bookId),
                onCheckoutTap: () => _openCheckout(context, ref, cart),
              ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.cart, required this.onRemove, required this.onCheckoutTap});

  final Cart cart;
  final ValueChanged<int> onRemove;
  final VoidCallback onCheckoutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _CartItemTile(
                item: item,
                onRemove: () => onRemove(item.book.id),
              );
            },
          ),
        ),
        _CartSummary(cartTotal: cart.total, onCheckoutTap: onCheckoutTap),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onRemove});

  final CartItemEntry item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 72,
            child: item.book.cover != null
                ? Image.network(
                    item.book.cover!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                  )
                : const _CoverPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.book.price.toStringAsFixed(0)} ₽',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Удалить из корзины',
          onPressed: onRemove,
        ),
      ],
    );
  }
}

/// Поле промокода + блок расчёта. Держит свой `TextEditingController` и
/// следит за `promoControllerProvider` — превью скидки живёт до тех пор,
/// пока пользователь не уйдёт с промокод-флоу; финальная сумма всё равно
/// пересчитывается на сервере при оформлении заказа.
class _CartSummary extends ConsumerStatefulWidget {
  const _CartSummary({required this.cartTotal, required this.onCheckoutTap});

  final double cartTotal;
  final VoidCallback onCheckoutTap;

  @override
  ConsumerState<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends ConsumerState<_CartSummary> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    try {
      await ref.read(promoControllerProvider.notifier).apply(code);
    } catch (_) {
      // ошибка уже осела в promoControllerProvider.error и показана ниже
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promoState = ref.watch(promoControllerProvider);
    final preview = promoState.preview;
    // Скидка считалась от суммы корзины на момент применения промокода —
    // если корзина с тех пор изменилась, считаем скидку неактуальной и не
    // показываем, чтобы не вводить в заблуждение (сумма товаров и итог
    // при этом показываются всегда — ТЗ).
    final promoApplies = preview != null && preview.subtotal == widget.cartTotal;
    final subtotal = widget.cartTotal;
    final discount = promoApplies ? preview.discount : 0.0;
    final total = promoApplies ? preview.total : subtotal;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Промокод',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: promoState.isLoading ? null : _applyPromo,
                  child: promoState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Применить'),
                ),
              ],
            ),
            if (promoState.error != null) ...[
              const SizedBox(height: 4),
              Text(
                promoState.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            AmountRow(label: 'Сумма товаров', value: subtotal),
            if (discount > 0) AmountRow(label: 'Скидка по промокоду', value: -discount),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Итого', style: theme.textTheme.titleMedium),
                Text(
                  '${total.toStringAsFixed(0)} ₽',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: widget.onCheckoutTap, child: const Text('Оформить заказ')),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.menu_book_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
