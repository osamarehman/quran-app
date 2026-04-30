import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../state/app_state.dart';

/// Stub for v0.2 Stage 1 (Agent B / Agent C): settings page with line-count
/// toggle, bookmarks list, and (filled by Agent C) reciter list + audio
/// toggle + bitrate. Until then, presents a minimal placeholder so the
/// route from TopBar still resolves.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
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
                final e = MushafEdition.all.firstWhere((m) => m.id == id);
                state.setEdition(e);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Audio on tap'),
            subtitle: const Text('Tap an ayah word to play it (stub)'),
            value: state.audioOnTap,
            onChanged: state.setAudioOnTap,
          ),
        ],
      ),
    );
  }
}
