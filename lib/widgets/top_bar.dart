import 'package:flutter/material.dart';

/// Stub for v0.2 Stage 1 (Agent B): replaces with a thin band containing
/// settings, bookmark, 15/16-line toggle, jump-to. Until then, retains the
/// page-counter prev/next chevrons so navigation still works.
class TopBar extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onOpenJumpTo;
  final bool isBookmarked;

  const TopBar({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    this.onPrev,
    this.onNext,
    this.onOpenSettings,
    this.onToggleBookmark,
    this.onOpenJumpTo,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            tooltip: 'Previous',
          ),
          Text('$pageNumber / $totalPages',
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}
