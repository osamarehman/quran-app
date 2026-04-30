import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mushaf/data/mushaf_db.dart';
import 'package:mushaf/widgets/marker_strip.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 28,
          height: 600,
          child: child,
        ),
      ),
    );

void main() {
  testWidgets('renders sajda glyph for an Al-A\'raf 7:206 line', (tester) async {
    final lines = [
      const MushafLine(
        pageNumber: 207,
        lineNumber: 1,
        lineType: 'ayah',
        isCentered: false,
        firstWordId: 1,
        lastWordId: 5,
      ),
    ];
    final wordsByLine = {
      1: const [
        MushafWord(
          id: 1,
          surah: 7,
          ayah: 206,
          wordIndex: 1,
          text: 'إِنَّ',
        ),
      ],
    };

    await tester.pumpWidget(_wrap(MarkerStrip(
      lines: lines,
      wordsByLine: wordsByLine,
      pageNumber: 207,
      width: 28,
    )));
    await tester.pump();

    // ARABIC PLACE OF SAJDAH glyph should be present.
    expect(find.text('۩'), findsOneWidget);
  });

  testWidgets('renders no markers on a basmallah-only page', (tester) async {
    final lines = [
      const MushafLine(
        pageNumber: 1,
        lineNumber: 1,
        lineType: 'basmallah',
        isCentered: true,
      ),
    ];

    await tester.pumpWidget(_wrap(MarkerStrip(
      lines: lines,
      wordsByLine: const {},
      pageNumber: 1,
      width: 28,
    )));
    await tester.pump();

    // No glyph text should appear.
    expect(find.text('۩'), findsNothing);
    expect(find.text('ع'), findsNothing);
    expect(find.text('م'), findsNothing);
    expect(find.text('حزب'), findsNothing);
    expect(find.text('ربع'), findsNothing);
    expect(find.text('نصف'), findsNothing);
    expect(find.text('ثلاثة'), findsNothing);
  });

  testWidgets('renders ruku glyph for an ayah that starts a ruku', (tester) async {
    // Al-Baqara 2:8 is the third ruku (kRukuStarts[2]).
    final lines = [
      const MushafLine(
        pageNumber: 3,
        lineNumber: 1,
        lineType: 'ayah',
        isCentered: false,
        firstWordId: 1,
        lastWordId: 1,
      ),
    ];
    final wordsByLine = {
      1: const [
        MushafWord(
          id: 1,
          surah: 2,
          ayah: 8,
          wordIndex: 1,
          text: 'وَمِنَ',
        ),
      ],
    };

    await tester.pumpWidget(_wrap(MarkerStrip(
      lines: lines,
      wordsByLine: wordsByLine,
      pageNumber: 3,
      width: 28,
    )));
    await tester.pump();

    expect(find.text('ع'), findsOneWidget);
  });
}
