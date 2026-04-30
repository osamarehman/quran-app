import 'package:flutter/material.dart';

import '../data/quran_metadata.dart';

/// Printed-mushaf style frame around a single page: thin border with a top
/// band showing the surah glyph (left) and juz incipit (right).
class PageFrame extends StatelessWidget {
  static const Color _borderColor = Color(0xFF888888);
  static const double _borderInset = 4.0;
  static const double _topBandHeight = 28.0;

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

    return Padding(
      padding: const EdgeInsets.all(_borderInset),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: _topBandHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    const Spacer(),
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
            Container(height: 1, color: _borderColor),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
