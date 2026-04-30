import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../state/app_state.dart';

/// Page-level settings: edition picker, audio toggle, reciter list (Agent C),
/// and bookmarks. Tapping a bookmark closes settings and returns the target
/// page to the caller via [Navigator.pop].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final bookmarks = state.bookmarks;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Display'),
          ListTile(
            title: const Text('Mushaf edition'),
            subtitle: Text(state.edition.label),
            trailing: DropdownButton<String>(
              value: state.edition.id,
              items: [
                for (final e in MushafEdition.all)
                  DropdownMenuItem(value: e.id, child: Text(e.label)),
              ],
              onChanged: (id) {
                if (id == null) return;
                final e =
                    MushafEdition.all.firstWhere((m) => m.id == id);
                state.setEdition(e);
              },
            ),
          ),
          const Divider(),
          const _SectionHeader('Audio'),
          SwitchListTile(
            title: const Text('Audio on tap'),
            subtitle: const Text('Tap an ayah word to play it'),
            value: state.audioOnTap,
            onChanged: state.setAudioOnTap,
          ),
          // AGENT C: reciter list goes here.
          // Render a list of available reciters and call
          // `state.setReciter(id)` on selection. Use
          // `state.selectedReciterId` to mark the current one.
          const SizedBox.shrink(),
          const Divider(),
          _SectionHeader('Bookmarks (${bookmarks.length})'),
          if (bookmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No bookmarks yet. Tap the bookmark icon on a page to save it.',
              ),
            )
          else
            for (final page in bookmarks)
              Dismissible(
                key: ValueKey('bookmark-$page'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) => state.removeBookmark(page),
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text('Page $page'),
                  onTap: () => Navigator.of(context).pop<int>(page),
                  onLongPress: () => state.removeBookmark(page),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
