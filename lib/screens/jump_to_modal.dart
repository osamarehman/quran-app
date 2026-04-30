import 'package:flutter/material.dart';

/// Stub for v0.2 Stage 1 (Agent B): three-tab modal — by Surah, by Juz, by
/// Page — that returns the resolved page number. Until populated, just
/// returns null so callers degrade gracefully.
Future<int?> showJumpToModal(BuildContext context, {required int totalPages}) {
  return showModalBottomSheet<int?>(
    context: context,
    builder: (ctx) => const _JumpToBody(),
  );
}

class _JumpToBody extends StatelessWidget {
  const _JumpToBody();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Jump to … (Agent B fills this in)'),
      ),
    );
  }
}
