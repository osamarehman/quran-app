import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';
import 'page_frame.dart';

/// Vertical strip on the page's outside edge showing ruku, sajda, hizb, and
/// waqf-lazim glyphs aligned to the line they fall on. Cells use Expanded so
/// they line up vertically with the line column rendered by [MushafPage].
class MarkerStrip extends StatelessWidget {
  final List<MushafLine> lines;
  final Map<int, List<MushafWord>> wordsByLine;
  final int pageNumber;
  final double width;

  const MarkerStrip({
    super.key,
    required this.lines,
    required this.wordsByLine,
    required this.pageNumber,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(
                          top: BorderSide(
                            color: PageFrame.borderColor,
                            width: 1,
                          ),
                        ),
                ),
                child: _LineMarkerCell(
                  line: lines[i],
                  words: wordsByLine[lines[i].lineNumber] ?? const [],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Codepoints (any in a word's text) that mark a Quranic stop (waqf),
/// including waqf-lazim. Surfaced as a single 'م' glyph regardless of type.
const Set<int> _kWaqfCodepoints = {
  0x06D6, 0x06D7, 0x06D8, 0x06D9, 0x06DA,
};

class _LineMarkerCell extends StatelessWidget {
  final MushafLine line;
  final List<MushafWord> words;

  const _LineMarkerCell({required this.line, required this.words});

  @override
  Widget build(BuildContext context) {
    if (line.lineType != 'ayah' || words.isEmpty) {
      return const SizedBox.shrink();
    }

    final markers = <Widget>[];
    final seenAyahs = <(int, int)>{};
    var hasWaqf = false;

    for (final w in words) {
      if (!hasWaqf && w.text.runes.any(_kWaqfCodepoints.contains)) {
        hasWaqf = true;
      }
      if (!seenAyahs.add((w.surah, w.ayah))) continue;

      if (isSajda(w.surah, w.ayah)) {
        markers.add(const _Glyph('۩'));
      }
      if (w.wordIndex == 1) {
        if (rukuStartIndex(w.surah, w.ayah) != null) {
          markers.add(const _Glyph('ع'));
        }
        final hi = hizbStartIndex(w.surah, w.ayah);
        if (hi != null) markers.add(_HizbGlyph(hizbIndex: hi));
      }
    }

    if (hasWaqf) markers.add(const _Glyph('م'));
    if (markers.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < markers.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            markers[i],
          ],
        ],
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  final String text;
  const _Glyph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IndopakNastaleeq',
        fontSize: 12,
        height: 1.0,
        color: Color(0xFF666666),
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

/// Hizb glyph — Arabic label for the quarter of the juz. With hizbs counted
/// 0..59, hizb%4 selects: 0 → "حزب", 1 → "ربع", 2 → "نصف", 3 → "ثلاثة".
class _HizbGlyph extends StatelessWidget {
  final int hizbIndex;
  const _HizbGlyph({required this.hizbIndex});

  @override
  Widget build(BuildContext context) {
    final label = switch (hizbIndex % 4) {
      1 => 'ربع',
      2 => 'نصف',
      3 => 'ثلاثة',
      _ => 'حزب',
    };
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'IndopakNastaleeq',
        fontSize: 10,
        height: 1.0,
        color: Color(0xFF666666),
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
