import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';

/// Thin top band: settings, bookmark toggle, 15/16-line edition picker, and
/// jump-to. Swipe drives next/prev navigation in v0.2 so the chevrons are
/// hidden by default; pass [pageNumber]/[totalPages] + [onPrev]/[onNext] only
/// when a caller wants the legacy page-counter row back.
class TopBar extends StatelessWidget {
  static const double height = 44;

  final int? pageNumber;
  final int? totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onOpenJumpTo;
  final bool isBookmarked;

  final MushafEdition currentEdition;
  final ValueChanged<MushafEdition>? onSetEdition;

  const TopBar({
    super.key,
    required this.currentEdition,
    this.pageNumber,
    this.totalPages,
    this.onPrev,
    this.onNext,
    this.onOpenSettings,
    this.onToggleBookmark,
    this.onOpenJumpTo,
    this.isBookmarked = false,
    this.onSetEdition,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = cs.onSurface;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: iconColor,
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              tooltip: 'Settings',
              onPressed: onOpenSettings,
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              color: iconColor,
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
              onPressed: onToggleBookmark,
            ),
            _EditionPicker(
              current: currentEdition,
              onChanged: onSetEdition,
              foreground: iconColor,
            ),
            const Spacer(),
            if (pageNumber != null && totalPages != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$pageNumber / $totalPages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.menu_open),
              color: iconColor,
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              tooltip: 'Jump to',
              onPressed: onOpenJumpTo,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionPicker extends StatelessWidget {
  final MushafEdition current;
  final ValueChanged<MushafEdition>? onChanged;
  final Color foreground;

  const _EditionPicker({
    required this.current,
    required this.onChanged,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MushafEdition>(
      tooltip: 'Mushaf edition',
      enabled: onChanged != null,
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final e in MushafEdition.all)
          PopupMenuItem<MushafEdition>(
            value: e,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: e.id == current.id
                      ? const Icon(Icons.check, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(e.label),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, size: 18, color: foreground),
            const SizedBox(width: 4),
            Text(
              '${current.linesPerPage}',
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: foreground),
          ],
        ),
      ),
    );
  }
}
