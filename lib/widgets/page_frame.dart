import 'package:flutter/material.dart';

import '../data/quran_metadata.dart';

/// Printed-mushaf style frame around a single page: thin border with a top
/// band showing the surah glyph (left) and juz incipit (right).
class PageFrame extends StatelessWidget {
  static const Color borderColor = Color(0xFF888888);
  static const double _borderInset = 4.0;
  static const double _topBandHeight = 28.0;
  /// Width of the marker strip on the outside edge. Mirrored here so the
  /// header band can pad the juz/surah labels to align with the *text*
  /// outer edge (not the page border, which sits behind the strip).
  static const double markerStripWidth = 28.0;
  static const double _bandHorizontalPadding = 8.0;

  final int pageNumber;

  /// The page's primary surah number, used to render the SurahName glyph
  /// (codepoint 0xE001 + (surahNumber - 1)).
  final int surahNumber;

  /// (surah, ayah) of the first ayah-typed line on the page; used to look up
  /// which juz the page belongs to.
  final int firstAyahSurah;
  final int firstAyahNumber;

  final Widget child;

  const PageFrame({
    super.key,
    required this.pageNumber,
    required this.surahNumber,
    required this.firstAyahSurah,
    required this.firstAyahNumber,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final juzName = kJuzNamesAr[juzForAyah(firstAyahSurah, firstAyahNumber) - 1];
    final surahGlyph = String.fromCharCode(0xE001 + (surahNumber - 1));
    // Strip sits on the outside edge of the spread: odd pages → right.
    // The text column ends one strip-width inside that edge, so we pad the
    // header label on the strip side to keep it aligned with the text,
    // not with the page-frame border.
    final stripOnRight = pageNumber.isOdd;
    final leftInset = _bandHorizontalPadding +
        (stripOnRight ? 0 : markerStripWidth);
    final rightInset = _bandHorizontalPadding +
        (stripOnRight ? markerStripWidth : 0);

    return Padding(
      padding: const EdgeInsets.all(_borderInset),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: _topBandHeight,
              child: Padding(
                padding: EdgeInsets.only(left: leftInset, right: rightInset),
                child: Row(
                  children: [
                    Text(
                      surahGlyph,
                      style: const TextStyle(
                        fontFamily: 'SurahName',
                        fontSize: 22,
                        height: 1.0,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$pageNumber',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.0,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      juzName,
                      style: const TextStyle(
                        fontFamily: 'IndopakNastaleeq',
                        fontSize: 18,
                        height: 1.0,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: borderColor),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
