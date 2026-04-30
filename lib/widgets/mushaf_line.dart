import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';

const double kBaseFontSize = 28.0;
const TextStyle kBaseArabicStyle = TextStyle(
  fontFamily: 'IndopakNastaleeq',
  fontSize: kBaseFontSize,
  height: 1.0,
  color: Color(0xFF111111),
);
// Minimum visual gap between words even when a line is at full font size.
// Without this, spaceBetween can produce zero-gap lines that read as run-on.
const double kMinWordGap = 4.0;

/// Returns the maximum naturally-laid-out width across the lines on a page,
/// at base font size. Used by the page widget to decide whether a page is
/// "low density" (Fatiha) and should be rendered in a narrow centered column.
double pageMaxNaturalLineWidth(Map<int, List<MushafWord>> wordsByLine) {
  double maxWidth = 0;
  for (final words in wordsByLine.values) {
    if (words.isEmpty) continue;
    double sum = 0;
    for (final w in words) {
      final tp = TextPainter(
        text: TextSpan(text: w.text, style: kBaseArabicStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      sum += tp.size.width;
    }
    if (words.length > 1) {
      sum += kMinWordGap * (words.length - 1);
    }
    if (sum > maxWidth) maxWidth = sum;
  }
  return maxWidth;
}

class MushafLineWidget extends StatelessWidget {
  final MushafLine line;
  final List<MushafWord> words;
  final ValueChanged<MushafWord>? onWordTap;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.words,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (line.lineType) {
      case 'surah_name':
        return _SurahNameLine(surahNumber: line.surahNumber ?? 0);
      case 'basmallah':
        return const _BasmallahLine();
      case 'ayah':
      default:
        return _AyahLine(
          words: words,
          isCentered: line.isCentered,
          onWordTap: onWordTap,
        );
    }
  }
}

class _AyahLine extends StatelessWidget {
  final List<MushafWord> words;
  final bool isCentered;
  final ValueChanged<MushafWord>? onWordTap;

  const _AyahLine({
    required this.words,
    required this.isCentered,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _fitStyle(words, constraints.maxWidth);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: isCentered
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              for (final w in words)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(context, w),
                  child: Text(w.text, style: style),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, MushafWord w) {
    final cb = onWordTap;
    if (cb != null) {
      cb(w);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 800),
        content: Text('${w.surah}:${w.ayah} word ${w.wordIndex} — ${w.text}'),
      ),
    );
  }

  // Returns a TextStyle whose fontSize is scaled down from kBaseFontSize so
  // that the words fit edge-to-edge with at least kMinWordGap between each.
  // No-op when the line already fits at base size.
  static TextStyle _fitStyle(List<MushafWord> words, double maxWidth) {
    if (words.length < 2 || maxWidth <= 0) return kBaseArabicStyle;
    double totalWordWidth = 0;
    for (final w in words) {
      final tp = TextPainter(
        text: TextSpan(text: w.text, style: kBaseArabicStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      totalWordWidth += tp.size.width;
    }
    final neededWidth = totalWordWidth + kMinWordGap * (words.length - 1);
    if (neededWidth <= maxWidth) return kBaseArabicStyle;
    final scale = maxWidth / neededWidth;
    return kBaseArabicStyle.copyWith(fontSize: kBaseFontSize * scale);
  }
}

class _SurahNameLine extends StatelessWidget {
  final int surahNumber;
  const _SurahNameLine({required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Text(
          'سُورَة $surahNumber',
          style: const TextStyle(
            fontFamily: 'IndopakNastaleeq',
            fontSize: 22,
            color: Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _BasmallahLine extends StatelessWidget {
  const _BasmallahLine();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِیْمِ',
        style: TextStyle(
          fontFamily: 'IndopakNastaleeq',
          fontSize: 26,
          color: Color(0xFF111111),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
