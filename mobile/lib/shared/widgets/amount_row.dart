import 'package:flutter/material.dart';

/// Строка «подпись — сумма» в блоках расчёта корзины/оформления заказа.
class AmountRow extends StatelessWidget {
  const AmountRow({required this.label, required this.value, super.key});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text('${value.toStringAsFixed(0)} ₽', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
