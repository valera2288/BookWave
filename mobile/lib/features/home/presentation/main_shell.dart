import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/domain/app_user.dart';
import '../../catalog/presentation/screens/catalog_screen.dart';
import '../../library/presentation/screens/library_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import 'screens/home_screen.dart';

/// Индекс активной вкладки нижней навигации — вынесен из локального
/// State в провайдер, чтобы другие экраны (например, «Успешный заказ»)
/// могли переключить вкладку снаружи, не создавая второй экземпляр
/// экрана поверх основного стека.
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);

const libraryTabIndex = 2;

/// Нижняя навигационная панель с главного экрана (ТЗ).
///
/// `user == null` — роль «Гость»: ТЗ даёт ей доступ только к главной и
/// каталогу (Библиотека/Профиль — права «Читателя»), поэтому вкладки для
/// них не показываем вовсе, а не прячем действие за экраном входа по тапу —
/// они всё равно никуда не пустят без входа.
class MainShell extends ConsumerWidget {
  const MainShell({required this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainShellTabIndexProvider);
    final l10n = AppLocalizations.of(context)!;
    final isGuest = user == null;
    final pages = [
      HomeScreen(user: user),
      const CatalogScreen(),
      if (!isGuest) const LibraryScreen(),
      if (!isGuest) ProfileScreen(user: user!),
    ];
    final destinations = [
      NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.navHome),
      NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l10n.navCatalog),
      if (!isGuest)
        NavigationDestination(
          icon: const Icon(Icons.collections_bookmark_outlined),
          label: l10n.navLibrary,
        ),
      if (!isGuest)
        NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(mainShellTabIndexProvider.notifier).state = i,
        destinations: destinations,
      ),
    );
  }
}
