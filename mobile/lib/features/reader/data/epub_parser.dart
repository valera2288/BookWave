import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../domain/epub_book.dart';

const _headingTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

/// Одна запись оглавления из toc.ncx: заголовок + файл(+якорь), на который
/// она указывает.
class _NavEntry {
  const _NavEntry({required this.title, required this.file, required this.anchor});

  final String title;
  final String file;
  final String? anchor;
}

/// Свой разбор EPUB (zip + XHTML) на `archive`/`xml` — без сторонних
/// epub-пакетов: `flutter_epub_viewer` тянет WebView (падает нативно на
/// Windows), а `epub_view`/`epubx` конфликтуют по транзитивным зависимостям
/// (`image`/`rxdart`) с `pdfrx`. Формат простой (spine — упорядоченный
/// список xhtml-глав из content.opf), тот же разбор уже делает бэкенд для
/// фрагмента (`apps/files/services.py:build_epub_excerpt`).
///
/// Оглавление строим по `toc.ncx`, если он есть (у реальных книг — почти
/// всегда: у Gutenberg один физический xhtml-файл часто содержит СРАЗУ
/// несколько глав, и старая эвристика "первый заголовок файла = глава"
/// на таких файлах теряла все главы, кроме первой в каждом файле). Если
/// `toc.ncx` отсутствует или не разбирается — откатываемся на прежнее
/// поведение (первый заголовок каждого spine-файла), это по-прежнему
/// работает для простых/синтетических EPUB без штатного NCX.
Future<EpubBook> parseEpubFile(File file) async {
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  String readText(String name) {
    final entry = archive.findFile(name);
    if (entry == null) {
      throw StateError('EPUB: файл "$name" не найден в архиве');
    }
    return utf8.decode(entry.content as List<int>, allowMalformed: true);
  }

  final container = XmlDocument.parse(readText('META-INF/container.xml'));
  final rootfile = container
      .findAllElements('rootfile', namespaceUri: '*')
      .first
      .getAttribute('full-path')!;
  final opfDir = rootfile.contains('/') ? rootfile.substring(0, rootfile.lastIndexOf('/')) : '';
  String resolve(String href) => opfDir.isEmpty ? href : '$opfDir/$href';

  final opf = XmlDocument.parse(readText(rootfile));
  final manifest = <String, String>{};
  for (final item in opf.findAllElements('item', namespaceUri: '*')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id != null && href != null) manifest[id] = resolve(href);
  }
  final spineIds = opf
      .findAllElements('spine', namespaceUri: '*')
      .expand((spine) => spine.findElements('itemref', namespaceUri: '*'))
      .map((e) => e.getAttribute('idref'))
      .whereType<String>()
      .toList();

  final navEntries = _parseNcxNav(opf, manifest, readText, resolve);

  var chapters = navEntries.isEmpty
      ? const <EpubChapterData>[]
      : _buildChaptersFromNav(spineIds, manifest, archive, navEntries);

  if (chapters.isEmpty) {
    chapters = _buildChaptersPerFile(spineIds, manifest, archive);
  }

  final toc = [
    for (var i = 0; i < chapters.length; i++)
      EpubTocEntry(title: chapters[i].title, chapterIndex: i),
  ];

  return EpubBook(chapters: chapters, toc: toc);
}

/// Разбирает `toc.ncx` (если он указан в `<spine toc="...">` и есть в
/// манифесте) в плоский список записей оглавления, в порядке обхода
/// `navMap` (вложенность `navPoint` не важна для порядка — важен только
/// порядок следования).
List<_NavEntry> _parseNcxNav(
  XmlDocument opf,
  Map<String, String> manifest,
  String Function(String) readText,
  String Function(String) resolve,
) {
  XmlElement? spineEl;
  for (final el in opf.findAllElements('spine', namespaceUri: '*')) {
    spineEl = el;
    break;
  }
  final tocId = spineEl?.getAttribute('toc');
  if (tocId == null) return const [];
  final ncxHref = manifest[tocId];
  if (ncxHref == null) return const [];

  final XmlDocument ncx;
  try {
    ncx = XmlDocument.parse(readText(ncxHref));
  } catch (_) {
    return const [];
  }

  XmlElement? navMap;
  for (final el in ncx.findAllElements('navMap', namespaceUri: '*')) {
    navMap = el;
    break;
  }
  if (navMap == null) return const [];

  final entries = <_NavEntry>[];

  void walk(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.name.local == 'navPoint') {
        String? label;
        for (final navLabel in child.findElements('navLabel', namespaceUri: '*')) {
          for (final text in navLabel.findElements('text', namespaceUri: '*')) {
            label = text.innerText.trim();
            break;
          }
          break;
        }
        String? src;
        for (final content in child.findElements('content', namespaceUri: '*')) {
          src = content.getAttribute('src');
          break;
        }
        if (label != null && label.isNotEmpty && src != null) {
          final parts = src.split('#');
          entries.add(
            _NavEntry(
              title: label,
              file: resolve(parts[0]),
              anchor: parts.length > 1 ? parts[1] : null,
            ),
          );
        }
        walk(child);
      } else {
        walk(child);
      }
    }
  }

  walk(navMap);
  return entries;
}

/// Строит главы по реальным границам из NCX: новая глава начинается там,
/// где элемент (в т.ч. заголовок) несёт `id`, на который указывает запись
/// оглавления — независимо от того, сколько логических глав упаковано в
/// один физический spine-файл.
List<EpubChapterData> _buildChaptersFromNav(
  List<String> spineIds,
  Map<String, String> manifest,
  Archive archive,
  List<_NavEntry> navEntries,
) {
  final byFile = <String, Map<String, String>>{};
  for (final entry in navEntries) {
    (byFile[entry.file] ??= {})[entry.anchor ?? ''] = entry.title;
  }

  final chapters = <EpubChapterData>[];
  var currentBlocks = <EpubBlock>[];
  String? currentTitle;
  var chapterIndex = 0;
  var blockIndex = 0;

  void flush() {
    if (currentTitle == null && currentBlocks.isEmpty) return;
    // `currentTitle` может быть null только для самого первого flush (текст
    // до первой реальной точки оглавления — титульный лист, аннотация и
    // т.п.) — дальше он всегда берётся из найденного `navPoint`. Раз это
    // гарантированно не пронумерованная глава, не подписываем её "Глава 1" —
    // у реальной первой главы бывает точно такое же название, и в
    // оглавлении получались бы два неразличимых пункта подряд.
    chapters.add(
      EpubChapterData(title: currentTitle ?? 'Начало книги', blocks: currentBlocks),
    );
    chapterIndex++;
    currentBlocks = [];
    currentTitle = null;
    blockIndex = 0;
  }

  void addBlock(String text, EpubBlockType type) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    currentBlocks.add(
      EpubBlock(chapterIndex: chapterIndex, blockIndex: blockIndex++, text: trimmed, type: type),
    );
  }

  for (final spineId in spineIds) {
    final href = manifest[spineId];
    if (href == null) continue;
    final entry = archive.findFile(href);
    if (entry == null) continue;
    final fileAnchors = byFile[href];

    if (fileAnchors != null && fileAnchors.containsKey('')) {
      flush();
      currentTitle = fileAnchors[''];
    }

    final xhtml = utf8.decode(entry.content as List<int>, allowMalformed: true);
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xhtml);
    } catch (_) {
      continue;
    }

    void walk(XmlElement element) {
      final id = element.getAttribute('id');
      if (id != null && fileAnchors != null && fileAnchors.containsKey(id)) {
        flush();
        currentTitle = fileAnchors[id];
      }
      final tag = element.name.local.toLowerCase();
      if (_headingTags.contains(tag)) {
        addBlock(element.innerText, EpubBlockType.heading);
        return;
      }
      if (tag == 'p' || tag == 'blockquote') {
        addBlock(element.innerText, EpubBlockType.paragraph);
        return;
      }
      for (final child in element.children.whereType<XmlElement>()) {
        walk(child);
      }
    }

    for (final body in doc.findAllElements('body', namespaceUri: '*')) {
      for (final child in body.children.whereType<XmlElement>()) {
        walk(child);
      }
      break;
    }
  }

  flush();
  return chapters;
}

/// Старое поведение — запасной вариант для EPUB без `toc.ncx`: одна глава
/// на spine-файл, название — первый найденный заголовок.
List<EpubChapterData> _buildChaptersPerFile(
  List<String> spineIds,
  Map<String, String> manifest,
  Archive archive,
) {
  final chapters = <EpubChapterData>[];
  for (var chapterIndex = 0; chapterIndex < spineIds.length; chapterIndex++) {
    final href = manifest[spineIds[chapterIndex]];
    if (href == null) continue;
    final entry = archive.findFile(href);
    if (entry == null) continue;
    final xhtml = utf8.decode(entry.content as List<int>, allowMalformed: true);
    chapters.add(_parseWholeFileAsChapter(xhtml, chapterIndex));
  }
  return chapters;
}

EpubChapterData _parseWholeFileAsChapter(String xhtml, int chapterIndex) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xhtml);
  } catch (_) {
    return EpubChapterData(title: 'Глава ${chapterIndex + 1}', blocks: const []);
  }

  final blocks = <EpubBlock>[];
  var blockIndex = 0;
  String? title;

  void addBlock(String text, EpubBlockType type) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    blocks.add(
      EpubBlock(chapterIndex: chapterIndex, blockIndex: blockIndex++, text: trimmed, type: type),
    );
  }

  void walk(XmlElement element) {
    final tag = element.name.local.toLowerCase();
    if (_headingTags.contains(tag)) {
      final text = element.innerText.trim();
      title ??= text.isEmpty ? null : text;
      addBlock(text, EpubBlockType.heading);
      return;
    }
    if (tag == 'p' || tag == 'blockquote') {
      addBlock(element.innerText, EpubBlockType.paragraph);
      return;
    }
    for (final child in element.children.whereType<XmlElement>()) {
      walk(child);
    }
  }

  final bodies = doc.findAllElements('body', namespaceUri: '*');
  if (bodies.isNotEmpty) {
    for (final child in bodies.first.children.whereType<XmlElement>()) {
      walk(child);
    }
    if (blocks.isEmpty) {
      addBlock(bodies.first.innerText, EpubBlockType.paragraph);
    }
  }

  return EpubChapterData(title: title ?? 'Глава ${chapterIndex + 1}', blocks: blocks);
}
