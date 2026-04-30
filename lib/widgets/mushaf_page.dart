import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import 'marker_strip.dart';
import 'mushaf_line.dart';
import 'page_frame.dart';

const double kMarkerStripWidth = 28.0;

/// If a page's max natural line width is below this fraction of the available
/// width, the page is treated as "low density" (Fatiha-style) and rendered
/// in a centered narrow column.
const double kNarrowPageThreshold = 0.75;

/// Fraction of available width used when rendering a narrow page.
const double kNarrowPageWidthFraction = 0.7;

/// Shared 1px charcoal divider used by the page frame, the strip-vs-text
/// vertical dividers, and the per-line horizontal cell dividers — so they
/// all overlap to a single continuous grid.
const BorderSide kCellDivider = BorderSide(
  color: PageFrame.borderColor,
  width: 1,
);

class _PageData {
  final List<MushafLine> lines;
  final Map<int, List<MushafWord>> wordsByLine;
  _PageData(this.lines, this.wordsByLine);
}

/// Returns (primarySurah, firstAyahSurah, firstAyahNumber). Primary surah
/// prefers a surah_name line, else the smallest surah_number on the page,
/// else the first word's surah. First-ayah comes from the first word in
/// line order.
(int, int, int) _resolvePagePrimary(_PageData data) {
  MushafWord? firstWord;
  for (final l in data.lines) {
    final words = data.wordsByLine[l.lineNumber];
    if (words != null && words.isNotEmpty) {
      firstWord = words.first;
      break;
    }
  }

  int? primary;
  for (final l in data.lines) {
    if (l.lineType == 'surah_name' && l.surahNumber != null) {
      primary = l.surahNumber;
      break;
    }
  }
  if (primary == null) {
    for (final l in data.lines) {
      final s = l.surahNumber;
      if (s != null && (primary == null || s < primary)) primary = s;
    }
  }
  primary ??= firstWord?.surah ?? 1;
  return (primary, firstWord?.surah ?? primary, firstWord?.ayah ?? 1);
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
        final pageData = snap.data!;
        final (primarySurah, firstAyahSurah, firstAyahNumber) =
            _resolvePagePrimary(pageData);
        return PageFrame(
          pageNumber: widget.pageNumber,
          surahNumber: primarySurah,
          firstAyahSurah: firstAyahSurah,
          firstAyahNumber: firstAyahNumber,
          child: _PageBody(
            data: pageData,
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
        final lineColumnAvailableWidth =
            constraints.maxWidth - 2 * kMarkerStripWidth;
        final maxNatural = pageMaxNaturalLineWidth(data.wordsByLine);
        final narrow =
            lineColumnAvailableWidth > 0 &&
            maxNatural > 0 &&
            (maxNatural / lineColumnAvailableWidth) < kNarrowPageThreshold;

        final cellColumn = narrow
            ? _NarrowLineCells(
                data: data,
                onWordTap: onWordTap,
                maxWidth:
                    lineColumnAvailableWidth * kNarrowPageWidthFraction,
              )
            : _GriddedLineCells(data: data, onWordTap: onWordTap);

        final leftStrip = _StripCell(
          data: data,
          pageNumber: pageNumber,
          divider: const Border(right: kCellDivider),
        );
        final rightStrip = _StripCell(
          data: data,
          pageNumber: pageNumber,
          divider: const Border(left: kCellDivider),
        );

        return Row(
          children: [leftStrip, Expanded(child: cellColumn), rightStrip],
        );
      },
    );
  }
}

/// Marker strip wrapper that paints the inside-edge vertical divider
/// (left or right) so it kisses the line-cell horizontal dividers exactly.
class _StripCell extends StatelessWidget {
  final _PageData data;
  final int pageNumber;
  final Border divider;

  const _StripCell({
    required this.data,
    required this.pageNumber,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: divider),
      child: MarkerStrip(
        lines: data.lines,
        wordsByLine: data.wordsByLine,
        pageNumber: pageNumber,
        width: kMarkerStripWidth,
      ),
    );
  }
}

/// Full-width gridded layout: one cell per line with a 1px top divider on
/// every cell except the first. The page frame's outer border serves as the
/// outermost top/bottom; cell dividers + strip dividers form the inner grid.
class _GriddedLineCells extends StatelessWidget {
  final _PageData data;
  final ValueChanged<MushafWord>? onWordTap;

  const _GriddedLineCells({required this.data, required this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < data.lines.length; i++)
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0 ? null : const Border(top: kCellDivider),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                child: MushafLineWidget(
                  line: data.lines[i],
                  words: data.wordsByLine[data.lines[i].lineNumber] ??
                      const [],
                  onWordTap: onWordTap,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Narrow centered column for low-density pages (Fatiha). No cell borders —
/// the visual is a tight centered text block, not a grid.
class _NarrowLineCells extends StatelessWidget {
  final _PageData data;
  final ValueChanged<MushafWord>? onWordTap;
  final double maxWidth;

  const _NarrowLineCells({
    required this.data,
    required this.onWordTap,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
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
  }
}
