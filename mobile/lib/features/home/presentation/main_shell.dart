import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';
import '../../catalog/presentation/screens/catalog_screen.dart';
import '../../library/presentation/screens/library_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import 'screens/home_screen.dart';

/// Нижняя навигационная панель с главного экрана (ТЗ).
class MainShell extends StatefulWidget {
  const MainShell({required this.user, super.key});

  final AppUser user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(user: widget.user),
      const CatalogScreen(),
      const LibraryScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Каталог'),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            label: 'Библиотека',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}
