import 'package:flutter/material.dart';

import '../../../library/presentation/screens/library_screen.dart';
import '../../domain/order.dart';

/// Экран «Успешный заказ» из ТЗ: сообщение об успехе, номер заказа,
/// кнопка «Перейти в библиотеку».
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Заказ оформлен')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Заказ успешно оформлен',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Номер заказа: #${order.id}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                ),
                child: const Text('Перейти в библиотеку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
