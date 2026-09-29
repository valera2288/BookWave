import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../notifications/domain/notification_preference.dart';
import '../../../profile/presentation/screens/change_password_screen.dart';

/// «Настройки» из ТЗ: тема (светлая/тёмная/системная), язык интерфейса
/// (русский/английский, сразу переключает `MaterialApp.locale`),
/// push-категории, смена пароля.
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

  /// Подпись категории приходит с бэкенда только по-русски — переводим по
  /// коду категории; неизвестная категория — как прислал сервер.
  String _categoryLabel(NotificationPreference preference, AppLocalizations l10n) =>
      switch (preference.category) {
        'new_releases' => l10n.settingsPushNewReleases,
        'order_status' => l10n.settingsPushOrderStatus,
        'review_replies' => l10n.settingsPushReviewReplies,
        _ => preference.label,
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSettings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsAppearance),
          RadioGroup<String>(
            groupValue: user.theme,
            onChanged: (value) => _setTheme(value!),
            child: Column(
              children: [
                RadioListTile<String>(title: Text(l10n.settingsThemeLight), value: 'light'),
                RadioListTile<String>(title: Text(l10n.settingsThemeDark), value: 'dark'),
                RadioListTile<String>(title: Text(l10n.settingsThemeSystem), value: 'system'),
              ],
            ),
          ),
          _SectionHeader(l10n.settingsLanguage),
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
          _SectionHeader(l10n.settingsNotifications),
          if (_preferences != null)
            for (var i = 0; i < _preferences!.length; i++)
              SwitchListTile(
                title: Text(_categoryLabel(_preferences![i], l10n)),
                value: _preferences![i].enabled,
                onChanged: (value) => _togglePreference(i, value),
              )
          else if (_loadFailed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.settingsNotificationsLoadError),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          _SectionHeader(l10n.settingsAccount),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.changePasswordTitle),
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
