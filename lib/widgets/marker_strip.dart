import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';

/// Stub for v0.2 Stage 1 (Agent D): vertical strip on the page's outside
/// edge showing ruku / sajda / hizb / waqf-lazim glyphs aligned to the
/// matching line. Until Agent D populates this, the strip just reserves
/// horizontal width so the page layout already has room for it.
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
  Widget build(BuildContext context) => SizedBox(width: width);
}
