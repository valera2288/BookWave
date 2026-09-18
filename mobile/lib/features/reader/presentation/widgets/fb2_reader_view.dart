import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../domain/reader_settings.dart';

class Fb2Block {
  const Fb2Block({required this.text, required this.isTitle});

  final String text;
  final bool isTitle;
}

/// FB2 — базовый просмотр (ТЗ не требует полной функциональности читалки
/// для этого формата, готовых Flutter-пакетов под FB2 нет): свой разбор
/// XML в плоский список параграфов/заголовков секций и непрерывный скролл,
/// прогресс — по доле прокрутки.
class Fb2ReaderView extends StatefulWidget {
  const Fb2ReaderView({
    required this.file,
    required this.settings,
    required this.initialProgress,
    required this.onProgressChanged,
    super.key,
  });

  final File file;
  final ReaderSettings settings;
  final int initialProgress;
  final ValueChanged<int> onProgressChanged;

  @override
  State<Fb2ReaderView> createState() => _Fb2ReaderViewState();
}

class _Fb2ReaderViewState extends State<Fb2ReaderView> {
  final _scrollController = ScrollController();
  List<Fb2Block>? _blocks;
  bool _jumpedToInitial = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final content = await widget.file.readAsString();
    final document = XmlDocument.parse(content);
    final bodies = document.findAllElements('body');
    final blocks = <Fb2Block>[];
    if (bodies.isNotEmpty) {
      for (final section in bodies.first.findElements('section')) {
        _collectSection(section, blocks);
      }
    }
    if (mounted) setState(() => _blocks = blocks);
  }

  void _collectSection(XmlElement section, List<Fb2Block> blocks) {
    for (final child in section.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'title':
          final title = child.innerText.trim();
          if (title.isNotEmpty) blocks.add(Fb2Block(text: title, isTitle: true));
        case 'p':
          final text = child.innerText.trim();
          if (text.isNotEmpty) blocks.add(Fb2Block(text: text, isTitle: false));
        case 'section':
          _collectSection(child, blocks);
      }
    }
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    final percent = (position.pixels / position.maxScrollExtent * 100).clamp(0, 100).round();
    widget.onProgressChanged(percent);
  }

  void _jumpToInitialProgress() {
    if (_jumpedToInitial || widget.initialProgress <= 0) return;
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    _jumpedToInitial = true;
    _scrollController.jumpTo(maxExtent * widget.initialProgress / 100);
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
    final blocks = _blocks;
    if (blocks == null) {
      return const Center(child: CircularProgressIndicator());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialProgress());
    return ColoredBox(
      color: _backgroundColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return Padding(
            padding: EdgeInsets.only(
              top: block.isTitle ? 24 : 0,
              bottom: block.isTitle ? 16 : 12,
            ),
            child: Text(
              block.text,
              style: TextStyle(
                color: _textColor,
                fontSize: block.isTitle ? widget.settings.fontSize + 4 : widget.settings.fontSize,
                fontWeight: block.isTitle ? FontWeight.bold : FontWeight.normal,
                height: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
