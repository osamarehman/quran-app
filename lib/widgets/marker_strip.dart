import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';

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
          for (final line in lines)
            Expanded(
              child: _LineMarkerCell(
                line: line,
                words: wordsByLine[line.lineNumber] ?? const [],
              ),
            ),
        ],
      ),
    );
  }
}

/// Codepoints that, when present in a word's text, indicate a Quranic stop
/// (waqf) — including waqf-lazim. We surface a single 'م' glyph for any of
/// them; finer waqf-type rendering can come later.
const Set<int> _kWaqfCodepoints = {
  0x06D6, // SMALL HIGH LIGATURE SAD WITH LAM WITH ALEF MAKSURA
  0x06D7, // SMALL HIGH LIGATURE QAF WITH LAM WITH ALEF MAKSURA
  0x06D8, // SMALL HIGH MEEM INITIAL FORM
  0x06D9, // SMALL HIGH LAM ALEF
  0x06DA, // SMALL HIGH JEEM
};

bool _hasWaqf(String text) {
  for (final code in text.runes) {
    if (_kWaqfCodepoints.contains(code)) return true;
  }
  return false;
}

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

    // Track which ayahs we've already evaluated for ayah-level markers
    // (sajda, ruku-start, hizb-start) so multi-word ayahs don't double-count.
    final seenAyahs = <(int, int)>{};
    var hasWaqf = false;

    for (final w in words) {
      // Word-level: waqf signs can appear on any word in the line.
      if (!hasWaqf && _hasWaqf(w.text)) {
        hasWaqf = true;
      }

      final ayahKey = (w.surah, w.ayah);
      if (seenAyahs.add(ayahKey)) {
        // Sajda: any ayah on this line that's a sajda.
        if (isSajda(w.surah, w.ayah)) {
          markers.add(const _Glyph('۩')); // ARABIC PLACE OF SAJDAH
        }

        // Ruku-start: the ayah starts at this ruku, and word 1 of that ayah
        // appears on this line (i.e. the ayah actually begins on this line).
        if (w.wordIndex == 1 && rukuStartIndex(w.surah, w.ayah) != null) {
          markers.add(const _Glyph('ع')); // ARABIC LETTER AIN
        }

        // Hizb-start: similarly, only when the ayah begins on this line.
        if (w.wordIndex == 1) {
          final hi = hizbStartIndex(w.surah, w.ayah);
          if (hi != null) {
            markers.add(_HizbGlyph(hizbIndex: hi));
          }
        }
      }
    }

    if (hasWaqf) {
      markers.add(const _Glyph('م')); // ARABIC LETTER MEEM
    }

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

/// Hizb glyph — a short Arabic label indicating which quarter of the juz
/// this hizb is. With hizbs counted 0..59, hizb%4 selects the quarter:
/// 0 -> "حزب" (full hizb), 1 -> "ربع", 2 -> "نصف", 3 -> "ثلاثة".
/// (The full hizb itself starts each juz alternation; this gives a single
/// muted-grey badge so the page doesn't get over-decorated.)
class _HizbGlyph extends StatelessWidget {
  final int hizbIndex; // 0..59
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
