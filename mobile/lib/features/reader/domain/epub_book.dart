enum EpubBlockType { title, heading, paragraph }

/// Один смысловой блок текста внутри главы (абзац/заголовок), с адресом
/// вида "индекс_главы:индекс_блока" — этот же адрес используется как
/// "position" для закладок (см. `Bookmark.position` на бэкенде — CFI-like
/// строка, непрозрачная для сервера) и как цель поиска/оглавления.
class EpubBlock {
  const EpubBlock({
    required this.chapterIndex,
    required this.blockIndex,
    required this.text,
    required this.type,
  });

  final int chapterIndex;
  final int blockIndex;
  final String text;
  final EpubBlockType type;

  String get position => '$chapterIndex:$blockIndex';
}

class EpubChapterData {
  const EpubChapterData({required this.title, required this.blocks});

  final String title;
  final List<EpubBlock> blocks;
}

class EpubTocEntry {
  const EpubTocEntry({required this.title, required this.chapterIndex});

  final String title;
  final int chapterIndex;
}

class EpubSearchResult {
  const EpubSearchResult({required this.excerpt, required this.position});

  final String excerpt;
  final String position;
}

/// Разобранная книга целиком — главы с блоками текста + оглавление.
class EpubBook {
  const EpubBook({required this.chapters, required this.toc});

  final List<EpubChapterData> chapters;
  final List<EpubTocEntry> toc;

  List<EpubBlock> get allBlocks => [for (final chapter in chapters) ...chapter.blocks];

  List<EpubSearchResult> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final results = <EpubSearchResult>[];
    for (final block in allBlocks) {
      final haystack = block.text.toLowerCase();
      if (haystack.contains(needle)) {
        final start = haystack.indexOf(needle);
        final excerptStart = (start - 30).clamp(0, block.text.length);
        final excerptEnd = (start + needle.length + 60).clamp(0, block.text.length);
        results.add(
          EpubSearchResult(
            excerpt: block.text.substring(excerptStart, excerptEnd),
            position: block.position,
          ),
        );
      }
    }
    return results;
  }
}
