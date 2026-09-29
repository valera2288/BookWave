import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) description;
}

final _slides = [
  _OnboardingSlide(
    icon: Icons.menu_book_outlined,
    title: (l10n) => l10n.onboardingSlide1Title,
    description: (l10n) => l10n.onboardingSlide1Description,
  ),
  _OnboardingSlide(
    icon: Icons.auto_stories_outlined,
    title: (l10n) => l10n.onboardingSlide2Title,
    description: (l10n) => l10n.onboardingSlide2Description,
  ),
  _OnboardingSlide(
    icon: Icons.bookmark_added_outlined,
    title: (l10n) => l10n.onboardingSlide3Title,
    description: (l10n) => l10n.onboardingSlide3Description,
  ),
  _OnboardingSlide(
    icon: Icons.collections_bookmark_outlined,
    title: (l10n) => l10n.onboardingSlide4Title,
    description: (l10n) => l10n.onboardingSlide4Description,
  ),
];

/// «Экран приветствия» из ТЗ: 3-4 слайда, «Далее»/«Пропустить», «Начать»
/// на последнем. Показывается один раз до первого входа/регистрации —
/// см. `AppPreferences.hasSeenOnboarding` и гейтинг в `app.dart`.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onFinish, super.key});

  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _isLast ? null : widget.onFinish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96, color: theme.colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          slide.title(l10n),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description(l10n),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? l10n.onboardingStart : l10n.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
