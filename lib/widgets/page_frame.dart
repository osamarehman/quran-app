import 'package:flutter/material.dart';

/// Stub for v0.2 Stage 1 (Agent A): wraps a single mushaf page in the
/// printed-style outer border + thin top band with surah glyph (left) and
/// juz Arabic name (right). Until Agent A populates this, it just passes
/// the child through.
class PageFrame extends StatelessWidget {
  final int pageNumber;
  final Widget child;

  const PageFrame({
    super.key,
    required this.pageNumber,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}
