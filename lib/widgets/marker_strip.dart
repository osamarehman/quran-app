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
  /// that line. Detection runs forward: when a line's FIRST word starts at
  /// a known ruku-start (kRukuStarts), the immediately preceding content
  /// line is the end of the previous ruku.
  ///
  /// Why first-word-of-next-line and not last-word-of-this-line: ayah-end
  /// glyphs are stored as the final wordIndex of the ayah and frequently
  /// wrap to the start of the next line. Checking the next line's first
  /// word avoids a class of false negatives where the ayah-end glyph and
  /// the next ayah's words share a line.
  ///
  /// Last-line-of-page fallback handles ruku-ends that fall at the bottom
  /// of a page: if its last word sits at a known ruku-end ayah, render the
  /// badge there.
  Map<int, int> _computeRukuEnds() {
    final out = <int, int>{};
    for (var i = 0; i < lines.length; i++) {
      final words = wordsByLine[lines[i].lineNumber] ?? const <MushafWord>[];
      if (words.isEmpty) continue;
      final first = words.first;
      final newRuku = rukuStartIndex(first.surah, first.ayah);
      if (newRuku == null || newRuku == 0) continue;
      // Walk back to the closest line that actually carries content.
      for (var j = i - 1; j >= 0; j--) {
        final prev = wordsByLine[lines[j].lineNumber] ?? const <MushafWord>[];
        if (prev.isNotEmpty) {
          out[j] = newRuku - 1;
          break;
        }
      }
    }
    final lastIdx = lines.length - 1;
    if (lastIdx >= 0 && !out.containsKey(lastIdx)) {
      final lw = wordsByLine[lines[lastIdx].lineNumber] ?? const <MushafWord>[];
      if (lw.isNotEmpty) {
        final re = rukuEndIndex(lw.last.surah, lw.last.ayah);
        if (re != null) out[lastIdx] = re;
      }
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
          if (label != null) markers.add(_Glyph(label, fontSize: 11));
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
    const numberStyle = TextStyle(
      fontSize: 10,
      height: 1.0,
      fontWeight: FontWeight.w600,
      color: Color(0xFF333333),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_arabicIndic('$juz'), style: numberStyle),
        const SizedBox(height: 1),
        const Text(
          'ع',
          style: TextStyle(
            fontFamily: 'IndopakNastaleeq',
            fontSize: 18,
            height: 1.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        if (ruku != null) ...[
          const SizedBox(height: 1),
          Text(_arabicIndic('$ruku'), style: numberStyle),
        ],
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
