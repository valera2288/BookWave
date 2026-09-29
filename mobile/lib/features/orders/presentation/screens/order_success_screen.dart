import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/main_shell.dart';
import '../../domain/order.dart';

/// Экран «Успешный заказ» из ТЗ: сообщение об успехе, номер заказа,
/// кнопка «Перейти в библиотеку».
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderSuccessTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.orderSuccessMessage,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.orderSuccessNumber(order.id),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  // Библиотека уже живёт в MainShell (вкладка нижней
                  // навигации) — переключаем на неё и возвращаемся к
                  // корневому экрану, а не пушим второй экземпляр
                  // LibraryScreen поверх стека (там не было бы даже
                  // нижней панели навигации).
                  ref.read(mainShellTabIndexProvider.notifier).state = libraryTabIndex;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(l10n.orderSuccessGoToLibrary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
