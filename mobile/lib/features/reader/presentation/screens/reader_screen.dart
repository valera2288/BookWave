import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/epub_book.dart';
import '../../domain/reader_settings.dart';
import '../reader_providers.dart';
import '../reader_settings_controller.dart';
import '../widgets/epub_reader_view.dart';
import '../widgets/fb2_reader_view.dart';
import '../widgets/pdf_reader_view.dart';

/// Читалка (ТЗ, «Требования к чтению книги»): EPUB — полная функциональность
/// (постраничная/непрерывная навигация, шрифт, тема, оглавление, поиск с
/// подсветкой, закладки), PDF/FB2 — базовый просмотр. В режиме фрагмента
/// (`isExcerpt`, вызывается с карточки книги для некупленных книг) закладки
/// и синхронизация прогресса отключены — сервер их для некупленной книги и
/// не примет (см. `apps/bookmarks/views.py`, `apps/library/views.py`).
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.bookId,
    required this.title,
    required this.format,
    required this.isExcerpt,
    this.initialProgress = 0,
    super.key,
  });

  final int bookId;
  final String title;
  final String format;
  final bool isExcerpt;
  final int initialProgress;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with WidgetsBindingObserver {
  SimpleEpubController? _epubController;
  PdfViewerController? _pdfController;
  List<EpubTocEntry> _toc = [];
  String _lastEpubPosition = '';
  late int _currentProgress = widget.initialProgress;
  late int _savedProgress = widget.initialProgress;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.format == 'epub') _epubController = SimpleEpubController();
    if (widget.format == 'pdf') _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Свернули/закрыли приложение, не выходя из книги кнопкой «назад», —
  // это тоже «закрытие книги» (ТЗ), иначе прогресс терялся бы.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _saveProgress();
  }

  Future<void> _saveProgress() async {
    // ТЗ: прогресс сохраняется автоматически при каждом закрытии книги.
    // Фрагмент не привязан к библиотеке — сервер такое обновление всё равно
    // отклонит (нет LibraryEntry), поэтому и не пытаемся.
    final progress = _currentProgress;
    if (widget.isExcerpt || progress == _savedProgress) return;
    try {
      await ref.read(libraryApiProvider).updateProgress(
            bookId: widget.bookId,
            progress: progress,
            updatedAt: DateTime.now(),
          );
      _savedProgress = progress;
    } catch (_) {
      // Нет сети — не блокируем закрытие книги, просто не синхронизируем
      // на этот раз.
    }
  }

  Future<void> _saveProgressAndLeave() async {
    if (_leaving) return;
    _leaving = true;
    await _saveProgress();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildViewer(File file, ReaderSettings settings) {
    switch (widget.format) {
      case 'epub':
        return EpubReaderView(
          file: file,
          controller: _epubController!,
          settings: settings,
          initialProgress: widget.initialProgress,
          onTocReady: (toc) => setState(() => _toc = toc),
          onProgressChanged: (percent) => _currentProgress = percent,
          onCurrentPositionChanged: (position) => _lastEpubPosition = position,
        );
      case 'pdf':
        return PdfReaderView(
          filePath: file.path,
          controller: _pdfController!,
          initialProgress: widget.initialProgress,
          onDocumentLoaded: (_) {},
          onPageChanged: (page, total) {
            _currentProgress = total > 0 ? ((page / total) * 100).round().clamp(0, 100) : 0;
          },
        );
      case 'fb2':
        return Fb2ReaderView(
          file: file,
          settings: settings,
          initialProgress: widget.initialProgress,
          onProgressChanged: (percent) => _currentProgress = percent,
        );
      default:
        return Center(child: Text(AppLocalizations.of(context)!.readerFormatUnsupported));
    }
  }

  Future<void> _openToc() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: _toc.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.readerTocUnavailable),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in _toc)
                    ListTile(
                      title: Text(entry.title),
                      onTap: () {
                        _epubController?.jumpToPosition('${entry.chapterIndex}:0');
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final controller = _epubController;
    if (controller == null) return;
    final queryController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    // Снаружи builder'а: StatefulBuilder перезапускает builder на каждый
    // setSheetState, и локальная переменная внутри сбрасывалась бы в [].
    var results = <EpubSearchResult>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void runSearch(String value) {
            final query = value.trim();
            if (query.length < 2) {
              setSheetState(() => results = []);
              return;
            }
            controller.highlight(query);
            setSheetState(() => results = controller.search(query));
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: queryController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.readerSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: runSearch,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(l10n.catalogEmptyResults),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final result = results[index];
                            return ListTile(
                              title: Text(
                                result.excerpt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                controller.jumpToPosition(result.position);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBookmarks() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final bookmarksAsync = ref.watch(bookmarksProvider(widget.bookId));
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.readerBookmarksTitle, style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(l10n.readerBookmarkAddHere),
                        onPressed: _lastEpubPosition.isEmpty
                            ? null
                            : () => ref
                                .read(bookmarksProvider(widget.bookId).notifier)
                                .add(_lastEpubPosition),
                      ),
                    ],
                  ),
                ),
                bookmarksAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.readerBookmarksLoadError),
                  ),
                  data: (bookmarks) => bookmarks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(l10n.readerBookmarksEmpty),
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: bookmarks.length,
                            itemBuilder: (context, index) {
                              final bookmark = bookmarks[index];
                              return ListTile(
                                leading: const Icon(Icons.bookmark),
                                title: Text(l10n.readerBookmarkTitle(index + 1)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref
                                      .read(bookmarksProvider(widget.bookId).notifier)
                                      .remove(bookmark.id),
                                ),
                                onTap: () {
                                  _epubController?.jumpToPosition(bookmark.position);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSettings() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(readerSettingsProvider).valueOrNull;
          if (settings == null) return const SizedBox.shrink();
          final notifier = ref.read(readerSettingsProvider.notifier);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.readerFontSize, style: Theme.of(context).textTheme.titleSmall),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: settings.fontSizeIndex > 0
                            ? () => notifier.setFontSizeIndex(settings.fontSizeIndex - 1)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: settings.fontSizeIndex.toDouble(),
                          min: 0,
                          max: (ReaderSettings.fontSizes.length - 1).toDouble(),
                          divisions: ReaderSettings.fontSizes.length - 1,
                          label: settings.fontSize.round().toString(),
                          onChanged: (value) => notifier.setFontSizeIndex(value.round()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: settings.fontSizeIndex < ReaderSettings.fontSizes.length - 1
                            ? () => notifier.setFontSizeIndex(settings.fontSizeIndex + 1)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.readerTheme, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in ReaderThemeMode.values)
                        ChoiceChip(
                          label: Text(mode.label(l10n)),
                          selected: settings.theme == mode,
                          onSelected: (_) => notifier.setTheme(mode),
                        ),
                    ],
                  ),
                  if (widget.format == 'epub') ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.readerContinuousScroll),
                      value: settings.continuousScroll,
                      onChanged: (value) => notifier.setContinuousScroll(value),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(
      readerFileProvider((bookId: widget.bookId, format: widget.format)),
    );
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveProgressAndLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (widget.format == 'epub') ...[
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n.readerSearchTooltip,
                onPressed: _openSearch,
              ),
              IconButton(
                icon: const Icon(Icons.toc),
                tooltip: l10n.readerTocTooltip,
                onPressed: _openToc,
              ),
              if (!widget.isExcerpt)
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: l10n.readerBookmarksTitle,
                  onPressed: _openBookmarks,
                ),
            ],
            if (widget.format != 'pdf')
              IconButton(
                icon: const Icon(Icons.text_fields),
                tooltip: l10n.readerSettingsTooltip,
                onPressed: _openSettings,
              ),
          ],
        ),
        body: fileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.readerFileLoadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    readerFileProvider((bookId: widget.bookId, format: widget.format)),
                  ),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
          data: (file) {
            final settingsAsync = ref.watch(readerSettingsProvider);
            final settings = settingsAsync.valueOrNull;
            if (settings == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildViewer(file, settings);
          },
        ),
      ),
    );
  }
}
