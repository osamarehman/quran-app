import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';

/// Vertical strip on the page's outside edge showing ruku, sajda, and
/// hizb-quarter (1/4 / 1/2 / 3/4) glyphs aligned to the line they fall on.
/// Cells use Expanded so they line up vertically with the line column.
/// Strip cells DO NOT carry top borders — the strip is one continuous column
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

    for (final w in words) {
      if (!seenAyahs.add((w.surah, w.ayah))) continue;

      if (isSajda(w.surah, w.ayah)) {
        markers.add(const _Glyph('۩'));
      }
      if (w.wordIndex == 1) {
        if (rukuStartIndex(w.surah, w.ayah) != null) {
          markers.add(_RukuBadge(surah: w.surah, ayah: w.ayah));
        }
        final qi = hizbQuarterIndex(w.surah, w.ayah);
        if (qi != null) {
          // qi%4: 0 = hizb/juz start — hidden per spec.
          //       1 = 1/4, 2 = 1/2, 3 = 3/4 — shown.
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

/// Ruku marker: ع centred, with juz number and surah-ruku number in
/// Arabic-Indic numerals stacked tightly below.
class _RukuBadge extends StatelessWidget {
  final int surah;
  final int ayah;
  const _RukuBadge({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final juz = juzForAyah(surah, ayah);
    final ruku = rukuNumberInSurah(surah, ayah);
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
