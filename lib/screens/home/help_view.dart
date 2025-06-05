import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HelpView extends StatefulWidget {
  final String? toBookmark;
  const HelpView({super.key, this.toBookmark});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  late PdfBookmarkBase _pdfBookmarkBase;

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'Roth Analysis Help Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: <Widget>[
          Tooltip(
            message: 'Open TOC',
            child: IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () {
                _pdfViewerKey.currentState?.openBookmarkView();
              },
            ),
          ),
        ],
      ),
      body: SfPdfViewer.asset(
        "assets/help.pdf",
        controller: _pdfViewerController,
        key: _pdfViewerKey,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          _pdfBookmarkBase = details.document.bookmarks;
          if (widget.toBookmark != null) {
            jumpToBookmark(_pdfBookmarkBase, widget.toBookmark!);
          }
        },
      ),
    );
  }

  void jumpToBookmark(PdfBookmarkBase bookmarkBase, String toBookmark) {
    for (int i = 0; i < bookmarkBase.count; i++) {
      PdfBookmark bookmark = bookmarkBase[i];
      if (bookmark.title == toBookmark) {
        _pdfViewerController.jumpToBookmark(bookmark);
      }
      if (bookmark.count != 0) {
        jumpToBookmark(bookmark, toBookmark);
      }
    }
  }
}
