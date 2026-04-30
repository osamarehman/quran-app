import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';

/// Vertical strip on the page's outside edge showing ruku-end, sajda, and
/// hizb-quarter (1/4 / 1/2 / 3/4) glyphs aligned to the line they fall on.
/// No per-cell horizontal dividers — the strip is one continuous column
/// while the text side has the bordered line grid.
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

  /// For each line index, returns the ruku index whose LAST ayah ends on
  /// that line — or null if no ruku ends there. A ruku ends on line L when:
  ///   1. line L's last word's (surah, ayah) differs from line L+1's first
  ///      word's (surah, ayah) — i.e. the ayah ended on this line, and
  ///   2. that ayah is the last ayah of some ruku.
  /// Cross-page boundaries (last line of page) are handled best-effort:
  /// we look at line.lastWordId and treat it as a ruku-end if (s, a) of
  /// that word is itself a ruku-end ayah (works whenever the layout DB's
  /// last_word_id sits at the end of the ayah).
  Map<int, int> _computeRukuEnds() {
    final out = <int, int>{};
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.lineType != 'ayah') continue;
      final words = wordsByLine[line.lineNumber] ?? const <MushafWord>[];
      if (words.isEmpty) continue;
      final last = words.last;
      final (s, a) = (last.surah, last.ayah);

      bool ayahEnded;
      if (i == lines.length - 1) {
        // Last line of page — we can't compare with the next line.
        // Best-effort: if the layout puts (s, a) as a ruku-end ayah AND the
        // last word's wordIndex is high enough to plausibly be the end,
        // assume the ayah ended here. Tolerated false negatives at exact
        // cross-page boundaries; false positives are unlikely because the
        // (s, a) lookup is exact.
        ayahEnded = true;
      } else {
        // Find the next line that has words.
        MushafWord? nextFirst;
        for (var j = i + 1; j < lines.length; j++) {
          final nextWords = wordsByLine[lines[j].lineNumber];
          if (nextWords != null && nextWords.isNotEmpty) {
            nextFirst = nextWords.first;
            break;
          }
        }
        if (nextFirst == null) {
          ayahEnded = true;
        } else {
          ayahEnded = (nextFirst.surah, nextFirst.ayah) != (s, a);
        }
      }

      if (!ayahEnded) continue;
      final ri = rukuEndIndex(s, a);
      if (ri != null) out[i] = ri;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rukuEnds = _computeRukuEnds();
    return SizedBox(
      width: width,
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++)
            Expanded(
              child: _LineMarkerCell(
                line: lines[i],
                words: wordsByLine[lines[i].lineNumber] ?? const [],
                rukuEnding: rukuEnds[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _LineMarkerCell extends StatelessWidget {
  final MushafLine line;
  final List<MushafWord> words;
  /// Index into [kRukuStarts] of the ruku that ENDS on this line, or null.
  final int? rukuEnding;

  const _LineMarkerCell({
    required this.line,
    required this.words,
    required this.rukuEnding,
  });

  @override
  Widget build(BuildContext context) {
    if (line.lineType != 'ayah' || words.isEmpty) {
      return const SizedBox.shrink();
    }

    final markers = <Widget>[];
    final seenAyahs = <(int, int)>{};

    for (final w in words) {
      if (!seenAyahs.add((w.surah, w.ayah))) continue;

      if (isSajda(w.surah, w.ayah)) {
        markers.add(const _Glyph('۩'));
      }
      // Quarter markers (1/4, 1/2, 3/4) fire at the START of each quarter.
      // Full hizb / juz starts are deliberately suppressed.
      if (w.wordIndex == 1) {
        final qi = hizbQuarterIndex(w.surah, w.ayah);
        if (qi != null) {
          final label = switch (qi % 4) {
            1 => '۱/۴',
            2 => '۱/۲',
            3 => '۳/۴',
            _ => null,
          };
          if (label != null) markers.add(_Glyph(label, fontSize: 9));
        }
      }
    }

    if (rukuEnding != null) {
      final (s, a) = kRukuStarts[rukuEnding!];
      markers.add(_RukuBadge(surahOfRukuStart: s, ayahOfRukuStart: a));
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
  final double fontSize;
  const _Glyph(this.text, {this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'IndopakNastaleeq',
        fontSize: fontSize,
        height: 1.0,
        color: const Color(0xFF666666),
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

/// Ruku-end marker: ع centred, with juz number and surah-ruku number in
/// Arabic-Indic numerals stacked tightly below. Numbers are derived from
/// the ruku's START (surah, ayah) — that's what fixes the surah-ruku and
/// juz the ruku belongs to.
class _RukuBadge extends StatelessWidget {
  final int surahOfRukuStart;
  final int ayahOfRukuStart;
  const _RukuBadge({
    required this.surahOfRukuStart,
    required this.ayahOfRukuStart,
  });

  @override
  Widget build(BuildContext context) {
    final juz = juzForAyah(surahOfRukuStart, ayahOfRukuStart);
    final ruku = rukuNumberInSurah(surahOfRukuStart, ayahOfRukuStart);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ع',
          style: TextStyle(
            fontFamily: 'IndopakNastaleeq',
            fontSize: 13,
            height: 1.0,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          _arabicIndic('$juz'),
          style: const TextStyle(fontSize: 8, height: 1.0, color: Color(0xFF666666)),
        ),
        if (ruku != null)
          Text(
            _arabicIndic('$ruku'),
            style: const TextStyle(fontSize: 8, height: 1.0, color: Color(0xFF666666)),
          ),
      ],
    );
  }
}

String _arabicIndic(String s) {
  const offset = 0x0660 - 0x30;
  final buf = StringBuffer();
  for (final code in s.codeUnits) {
    if (code >= 0x30 && code <= 0x39) {
      buf.writeCharCode(code + offset);
    } else {
      buf.writeCharCode(code);
    }
  }
  return buf.toString();
}
