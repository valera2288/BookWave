import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/epub_parser.dart';
import '../../domain/epub_book.dart';
import '../../domain/reader_settings.dart';

/// Императивный доступ к уже открытой книге — оглавление, поиск, переход
/// по адресу ("индекс_главы:индекс_блока", он же формат `position` для
/// закладок). Аналог `EpubController` из `flutter_epub_viewer`, но без
/// WebView под капотом.
class SimpleEpubController {
  _EpubReaderViewState? _state;

  void _attach(_EpubReaderViewState state) => _state = state;
  void _detach(_EpubReaderViewState state) {
    if (_state == state) _state = null;
  }

  List<EpubTocEntry> get toc => _state?._book?.toc ?? const [];

  List<EpubSearchResult> search(String query) => _state?._book?.search(query) ?? const [];

  void highlight(String query) => _state?._setHighlight(query);

  void jumpToPosition(String position) => _state?._jumpToPosition(position);
}

/// EPUB — основной формат читалки (ТЗ: «полная функциональность»):
/// постраничная/непрерывная навигация, темы, размер шрифта, оглавление,
/// поиск с подсветкой, прогресс — всё на чистом Flutter (см.
/// `data/epub_parser.dart` за тем, почему не готовый epub-пакет).
class EpubReaderView extends StatefulWidget {
  const EpubReaderView({
    required this.file,
    required this.controller,
    required this.settings,
    required this.initialProgress,
    required this.onTocReady,
    required this.onProgressChanged,
    required this.onCurrentPositionChanged,
    super.key,
  });

  final File file;
  final SimpleEpubController controller;
  final ReaderSettings settings;
  final int initialProgress;
  final ValueChanged<List<EpubTocEntry>> onTocReady;
  final ValueChanged<int> onProgressChanged;
  final ValueChanged<String> onCurrentPositionChanged;

  @override
  State<EpubReaderView> createState() => _EpubReaderViewState();
}

class _EpubReaderViewState extends State<EpubReaderView> {
  final _scrollController = ScrollController();
  final _pageController = PageController();
  EpubBook? _book;
  bool _jumpedToInitial = false;
  String? _highlightQuery;

  // Постраничный режим: страница — глава со своим скроллом. Чтобы прогресс,
  // закладки и возврат к месту чтения работали внутри главы, а не только по
  // её началу, у каждой главы свой ScrollController, а у каждого блока —
  // ключ для точного перехода (Scrollable.ensureVisible).
  final _chapterScrollControllers = <int, ScrollController>{};
  final _blockKeys = <String, GlobalKey>{};
  List<int> _chapterStarts = const [];
  int _totalBlocks = 0;
  int _currentChapter = 0;
  String? _pendingPosition;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _scrollController.dispose();
    _pageController.dispose();
    for (final controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final book = await parseEpubFile(widget.file);
    if (!mounted) return;
    final starts = <int>[];
    var total = 0;
    for (final chapter in book.chapters) {
      starts.add(total);
      total += chapter.blocks.length;
    }
    setState(() {
      _book = book;
      _chapterStarts = starts;
      _totalBlocks = total;
    });
    widget.onTocReady(book.toc);
  }

  ScrollController _chapterController(int chapterIndex) =>
      _chapterScrollControllers.putIfAbsent(chapterIndex, () {
        final controller = ScrollController();
        controller.addListener(() {
          if (chapterIndex == _currentChapter) _reportPagedPosition(chapterIndex);
        });
        return controller;
      });

  GlobalKey _blockKey(EpubBlock block) => _blockKeys.putIfAbsent(block.position, GlobalKey.new);

  /// Текущий блок главы — по доле прокрутки внутри неё; прогресс — доля
  /// этого блока среди всех блоков книги.
  void _reportPagedPosition(int chapterIndex, {bool withProgress = true}) {
    final book = _book;
    if (book == null) return;
    final blocks = book.chapters[chapterIndex].blocks;
    if (blocks.isEmpty) return;
    final controller = _chapterScrollControllers[chapterIndex];
    var fraction = 0.0;
    if (controller != null && controller.hasClients) {
      final position = controller.position;
      fraction = position.maxScrollExtent > 0
          ? (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0)
          : 1.0;
    }
    final blockIndex = (fraction * (blocks.length - 1)).round();
    widget.onCurrentPositionChanged(blocks[blockIndex].position);
    if (!withProgress) return;
    final globalIndex = _chapterStarts[chapterIndex] + blockIndex;
    final percent = _totalBlocks > 1 ? (globalIndex / (_totalBlocks - 1) * 100).round() : 100;
    widget.onProgressChanged(percent);
  }

  /// Переход к блоку в постраничном режиме: сначала на страницу главы,
  /// потом — прокрутка к самому блоку, когда страница построена.
  void _jumpToPagedPosition(String position, int chapterIndex) {
    _pendingPosition = position;
    if (_pageController.hasClients && _currentChapter != chapterIndex) {
      _pageController.jumpToPage(chapterIndex);
    }
    _applyPendingPosition(attemptsLeft: 5);
  }

  void _applyPendingPosition({required int attemptsLeft}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final position = _pendingPosition;
      if (!mounted || position == null) return;
      final blockContext = _blockKeys[position]?.currentContext;
      if (blockContext == null) {
        if (attemptsLeft > 0) {
          _applyPendingPosition(attemptsLeft: attemptsLeft - 1);
        } else {
          // Не дождались построения страницы — хотя бы остаёмся на главе и
          // не блокируем дальнейшие обновления позиции в onPageChanged.
          _pendingPosition = null;
          _reportPagedPosition(_currentChapter);
        }
        return;
      }
      _pendingPosition = null;
      Scrollable.ensureVisible(blockContext);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportPagedPosition(_currentChapter);
      });
    });
  }

  void _setHighlight(String query) => setState(() => _highlightQuery = query.trim());

  void _onScroll() {
    if (!widget.settings.continuousScroll) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    final fraction = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    widget.onProgressChanged((fraction * 100).round());
    final blocks = _book?.allBlocks;
    if (blocks != null && blocks.isNotEmpty) {
      final index = (fraction * (blocks.length - 1)).round();
      widget.onCurrentPositionChanged(blocks[index].position);
    }
  }

  void _jumpToInitialProgress() {
    if (_jumpedToInitial) return;
    final book = _book;
    if (book == null) return;
    _jumpedToInitial = true;
    if (widget.initialProgress <= 0) {
      // Без этого до первой прокрутки позиция пуста и «Закладка здесь»
      // недоступна на первой странице.
      if (!widget.settings.continuousScroll) {
        _reportPagedPosition(_currentChapter, withProgress: false);
      }
      return;
    }
    if (widget.settings.continuousScroll) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        _scrollController.jumpTo(maxExtent * widget.initialProgress / 100);
      }
    } else if (_totalBlocks > 0) {
      // Обратно к формуле _reportPagedPosition: процент -> блок книги.
      final globalIndex =
          ((widget.initialProgress / 100) * (_totalBlocks - 1)).round().clamp(0, _totalBlocks - 1);
      var chapterIndex = 0;
      while (chapterIndex + 1 < _chapterStarts.length &&
          _chapterStarts[chapterIndex + 1] <= globalIndex) {
        chapterIndex++;
      }
      final block = book.chapters[chapterIndex].blocks[globalIndex - _chapterStarts[chapterIndex]];
      _jumpToPagedPosition(block.position, chapterIndex);
    }
  }

  void _jumpToPosition(String position) {
    final book = _book;
    if (book == null) return;
    final chapterIndex = int.tryParse(position.split(':').first) ?? 0;

    if (widget.settings.continuousScroll) {
      if (!_scrollController.hasClients) return;
      final blocks = book.allBlocks;
      final targetIndex = blocks.indexWhere((b) => b.position == position);
      final effectiveIndex = targetIndex >= 0
          ? targetIndex
          : blocks.indexWhere((b) => b.chapterIndex == chapterIndex);
      if (effectiveIndex < 0 || blocks.isEmpty) return;
      final fraction = effectiveIndex / blocks.length;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent * fraction);
    } else {
      final clamped = chapterIndex.clamp(0, book.chapters.length - 1);
      final blocks = book.chapters[clamped].blocks;
      final exists = blocks.any((b) => b.position == position);
      if (!exists && blocks.isEmpty) {
        if (_pageController.hasClients) _pageController.jumpToPage(clamped);
        return;
      }
      _jumpToPagedPosition(exists ? position : blocks.first.position, clamped);
    }
  }

  Color get _backgroundColor {
    switch (widget.settings.theme) {
      case ReaderThemeMode.dark:
        return const Color(0xff121212);
      case ReaderThemeMode.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderThemeMode.light:
        return Colors.white;
    }
  }

  Color get _textColor {
    switch (widget.settings.theme) {
      case ReaderThemeMode.dark:
        return Colors.white;
      case ReaderThemeMode.sepia:
        return const Color(0xFF5B4636);
      case ReaderThemeMode.light:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    if (book == null) {
      return const Center(child: CircularProgressIndicator());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialProgress());

    if (widget.settings.continuousScroll) {
      final blocks = book.allBlocks;
      return ColoredBox(
        color: _backgroundColor,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: blocks.length,
          itemBuilder: (context, index) => _BlockText(
            block: blocks[index],
            settings: widget.settings,
            color: _textColor,
            highlightQuery: _highlightQuery,
          ),
        ),
      );
    }

    return ColoredBox(
      color: _backgroundColor,
      child: PageView.builder(
        controller: _pageController,
        itemCount: book.chapters.length,
        onPageChanged: (index) {
          _currentChapter = index;
          // Во время программного перехода позицию сообщит
          // _applyPendingPosition уже после прокрутки к нужному блоку.
          if (_pendingPosition == null) _reportPagedPosition(index);
        },
        itemBuilder: (context, index) => SingleChildScrollView(
          controller: _chapterController(index),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final block in book.chapters[index].blocks)
                _BlockText(
                  key: _blockKey(block),
                  block: block,
                  settings: widget.settings,
                  color: _textColor,
                  highlightQuery: _highlightQuery,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockText extends StatelessWidget {
  const _BlockText({
    required this.block,
    required this.settings,
    required this.color,
    required this.highlightQuery,
    super.key,
  });

  final EpubBlock block;
  final ReaderSettings settings;
  final Color color;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final isHeading = block.type == EpubBlockType.heading;
    final style = TextStyle(
      color: color,
      fontSize: isHeading ? settings.fontSize + 4 : settings.fontSize,
      fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
      height: 1.5,
    );
    return Padding(
      padding: EdgeInsets.only(top: isHeading ? 24 : 0, bottom: isHeading ? 16 : 12),
      child: RichText(text: TextSpan(style: style, children: _spans(block.text, style))),
    );
  }

  List<InlineSpan> _spans(String text, TextStyle baseStyle) {
    final query = highlightQuery;
    if (query == null || query.isEmpty) return [TextSpan(text: text)];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.yellow,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }
}
