import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// PDF — базовый просмотр (ТЗ прямо не требует полной функциональности
/// читалки для этого формата): постраничная навигация и зум из коробки,
/// прогресс — по номеру страницы. Свободный (не требующий лицензии) пакет
/// на PDFium — в отличие от коммерческих вьюеров, не показывает вотермарку.
class PdfReaderView extends StatelessWidget {
  const PdfReaderView({
    required this.filePath,
    required this.controller,
    required this.initialProgress,
    required this.onPageChanged,
    required this.onDocumentLoaded,
    super.key,
  });

  final String filePath;
  final PdfViewerController controller;
  final int initialProgress;
  final void Function(int page, int totalPages) onPageChanged;
  final ValueChanged<int> onDocumentLoaded;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.file(
      filePath,
      controller: controller,
      params: PdfViewerParams(
        onViewerReady: (document, controller) {
          final totalPages = document.pages.length;
          onDocumentLoaded(totalPages);
          if (initialProgress > 0 && totalPages > 0) {
            final page = ((initialProgress / 100) * totalPages).round().clamp(1, totalPages);
            controller.goToPage(pageNumber: page);
          }
        },
        onPageChanged: (pageNumber) {
          if (pageNumber != null) {
            onPageChanged(pageNumber, controller.pageCount);
          }
        },
      ),
    );
  }
}
