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
    super.dispose();
  }

  Future<void> _load() async {
    final book = await parseEpubFile(widget.file);
    if (!mounted) return;
    setState(() => _book = book);
    widget.onTocReady(book.toc);
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
    if (_jumpedToInitial || widget.initialProgress <= 0) return;
    final book = _book;
    if (book == null) return;
    _jumpedToInitial = true;
    if (widget.settings.continuousScroll) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        _scrollController.jumpTo(maxExtent * widget.initialProgress / 100);
      }
    } else if (book.chapters.length > 1) {
      final chapterIndex = ((widget.initialProgress / 100) * (book.chapters.length - 1))
          .round()
          .clamp(0, book.chapters.length - 1);
      if (_pageController.hasClients) _pageController.jumpToPage(chapterIndex);
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
    } else if (_pageController.hasClients) {
      _pageController.jumpToPage(chapterIndex.clamp(0, book.chapters.length - 1));
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
          final percent = book.chapters.length > 1
              ? (index / (book.chapters.length - 1) * 100).round()
              : 100;
          widget.onProgressChanged(percent);
          final chapterBlocks = book.chapters[index].blocks;
          if (chapterBlocks.isNotEmpty) {
            widget.onCurrentPositionChanged(chapterBlocks.first.position);
          }
        },
        itemBuilder: (context, index) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final block in book.chapters[index].blocks)
                _BlockText(
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
