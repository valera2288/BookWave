import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../notifications/domain/notification_preference.dart';
import '../../../profile/presentation/screens/change_password_screen.dart';

/// «Настройки» из ТЗ: тема (светлая/тёмная/системная), язык интерфейса
/// (русский/английский — переключатель сохраняется, но реального перевода
/// строк пока нет во всём приложении, см. ARCHITECTURE.md, раздел
/// «Известные ограничения»), push-категории, смена пароля.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<NotificationPreference>? _preferences;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await ref.read(notificationsApiProvider).fetchPreferences();
      if (mounted) setState(() => _preferences = preferences);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _setTheme(String theme) async {
    await ref.read(authRepositoryProvider).updateProfile(theme: theme);
    await ref.read(authControllerProvider.notifier).refreshUser();
  }

  Future<void> _setLanguage(String language) async {
    await ref.read(authRepositoryProvider).updateProfile(language: language);
    await ref.read(authControllerProvider.notifier).refreshUser();
  }

  Future<void> _togglePreference(int index, bool enabled) async {
    final preferences = _preferences;
    if (preferences == null) return;
    final previous = preferences[index];
    setState(() {
      preferences[index] = NotificationPreference(
        category: previous.category,
        label: previous.label,
        enabled: enabled,
      );
    });
    try {
      await ref
          .read(notificationsApiProvider)
          .updatePreference(category: previous.category, enabled: enabled);
    } catch (e) {
      setState(() => preferences[index] = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const _SectionHeader('Оформление'),
          RadioGroup<String>(
            groupValue: user.theme,
            onChanged: (value) => _setTheme(value!),
            child: const Column(
              children: [
                RadioListTile<String>(title: Text('Светлая тема'), value: 'light'),
                RadioListTile<String>(title: Text('Тёмная тема'), value: 'dark'),
                RadioListTile<String>(title: Text('Системная тема'), value: 'system'),
              ],
            ),
          ),
          const Divider(height: 1),
          RadioGroup<String>(
            groupValue: user.language,
            onChanged: (value) => _setLanguage(value!),
            child: const Column(
              children: [
                RadioListTile<String>(title: Text('Русский'), value: 'ru'),
                RadioListTile<String>(title: Text('English'), value: 'en'),
              ],
            ),
          ),
          const _SectionHeader('Уведомления'),
          if (_preferences != null)
            for (var i = 0; i < _preferences!.length; i++)
              SwitchListTile(
                title: Text(_preferences![i].label),
                value: _preferences![i].enabled,
                onChanged: (value) => _togglePreference(i, value),
              )
          else if (_loadFailed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Не удалось загрузить настройки уведомлений'),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const _SectionHeader('Аккаунт'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Сменить пароль'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
