import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/home_providers.dart';
import '../../../reader/presentation/screens/reader_screen.dart';
import '../../domain/library_entry.dart';
import '../library_providers.dart';

/// «Моя библиотека» из ТЗ: сетка купленных книг с индикатором прогресса
/// чтения поверх обложки, книги без начатого чтения помечены «Новая».
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, LibraryEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.libraryRemoveTitle),
        content: Text(l10n.libraryRemoveMessage(entry.book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(libraryApiProvider).removeFromLibrary(entry.book.id);
      ref.invalidate(libraryProvider);
      // Зеркально к чекауту (checkout_screen.dart): удалённая книга по ТЗ
      // снова может появиться в «Рекомендуем» («отсутствующие в его
      // библиотеке») — без инвалидации подборка осталась бы прежней.
      ref.invalidate(recommendationsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.libraryRemoveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLibrary)),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.libraryLoadError),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(libraryProvider),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (entries) => entries.isEmpty
            ? Center(child: Text(l10n.libraryEmpty))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(libraryProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LibraryCard(
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            bookId: entry.book.id,
                            title: entry.book.title,
                            format: entry.preferredFormat,
                            isExcerpt: false,
                            initialProgress: entry.progress,
                          ),
                        ),
                      ),
                      onRemove: () => _confirmRemove(context, ref, entry),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.entry, required this.onTap, required this.onRemove});

  final LibraryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = entry.book;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: book.cover != null
                        ? Image.network(
                            book.cover!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                          )
                        : const _CoverPlaceholder(),
                  ),
                ),
                if (entry.progress == 0)
                  const Positioned(top: 6, left: 6, child: _NewBadge())
                else
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ProgressOverlay(progress: entry.progress),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _RemoveButton(onPressed: onRemove),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (book.authors.isNotEmpty)
            Text(
              book.authors.map((a) => a.name).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 4,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progress%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
        tooltip: AppLocalizations.of(context)!.libraryRemoveTooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          AppLocalizations.of(context)!.libraryNewBadge,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
        size: 32,
      ),
    );
  }
}
