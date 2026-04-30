import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import 'marker_strip.dart';
import 'mushaf_line.dart';
import 'page_frame.dart';

/// Width of the page-edge marker strip. Kept here so MushafPage can reserve
/// the same width whether or not Agent D has filled in MarkerStrip yet.
const double kMarkerStripWidth = 28.0;

/// If a page's max natural line width is below this fraction of the available
/// width, the page is treated as "low density" (Fatiha-style) and rendered
/// in a centered narrow column.
const double kNarrowPageThreshold = 0.75;

/// Fraction of available width used when rendering a narrow page.
const double kNarrowPageWidthFraction = 0.7;

class _PageData {
  final List<MushafLine> lines;
  final Map<int, List<MushafWord>> wordsByLine;
  _PageData(this.lines, this.wordsByLine);
}

class MushafPage extends StatefulWidget {
  final MushafDb db;
  final int pageNumber;
  final ValueChanged<MushafWord>? onWordTap;

  const MushafPage({
    super.key,
    required this.db,
    required this.pageNumber,
    this.onWordTap,
  });

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late Future<_PageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber || oldWidget.db != widget.db) {
      _data = _load();
    }
  }

  Future<_PageData> _load() async {
    final lines = await widget.db.getPage(widget.pageNumber);
    final wordsByLine = <int, List<MushafWord>>{};
    for (final l in lines) {
      if (l.firstWordId != null && l.lastWordId != null) {
        wordsByLine[l.lineNumber] =
            await widget.db.getWords(l.firstWordId!, l.lastWordId!);
      }
    }
    return _PageData(lines, wordsByLine);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PageData>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Page load failed:\n${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PageFrame(
          pageNumber: widget.pageNumber,
          child: _PageBody(
            data: snap.data!,
            pageNumber: widget.pageNumber,
            onWordTap: widget.onWordTap,
          ),
        );
      },
    );
  }
}

class _PageBody extends StatelessWidget {
  final _PageData data;
  final int pageNumber;
  final ValueChanged<MushafWord>? onWordTap;

  const _PageBody({
    required this.data,
    required this.pageNumber,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve strip width on the outside edge of the page.
        // Odd page (right side of an RTL spread) → strip on right.
        final stripOnRight = pageNumber.isOdd;
        final strip = MarkerStrip(
          lines: data.lines,
          wordsByLine: data.wordsByLine,
          pageNumber: pageNumber,
          width: kMarkerStripWidth,
        );
        final lineColumnAvailableWidth =
            constraints.maxWidth - kMarkerStripWidth - 32; // 16 px padding x 2

        final maxNatural = pageMaxNaturalLineWidth(data.wordsByLine);
        final narrow =
            lineColumnAvailableWidth > 0 &&
            maxNatural > 0 &&
            (maxNatural / lineColumnAvailableWidth) < kNarrowPageThreshold;
        final lineMaxWidth = narrow
            ? lineColumnAvailableWidth * kNarrowPageWidthFraction
            : lineColumnAvailableWidth;

        final lineColumn = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: lineMaxWidth),
              child: Column(
                children: [
                  for (final l in data.lines)
                    Expanded(
                      child: MushafLineWidget(
                        line: l,
                        words: data.wordsByLine[l.lineNumber] ?? const [],
                        onWordTap: onWordTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        return Row(
          children: stripOnRight
              ? [Expanded(child: lineColumn), strip]
              : [strip, Expanded(child: lineColumn)],
        );
      },
    );
  }
}
