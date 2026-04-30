import 'package:flutter/material.dart';

import '../audio/reciter_catalog.dart';
import '../data/mushaf_db.dart';
import '../state/app_state.dart';

/// Settings screen — exposes mushaf edition, audio toggle, reciter picker,
/// and bitrate (for alquran.cloud reciters).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<List<Reciter>>? _reciterFuture;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _reciterFuture = ReciterCatalog().all();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ReciterCatalog().refresh();
    } finally {
      if (mounted) {
        setState(() {
          _reciterFuture = ReciterCatalog().all();
          _refreshing = false;
        });
      }
    }
  }

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
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Audio on tap'),
            subtitle: const Text('Tap an ayah word to play it'),
            value: state.audioOnTap,
            onChanged: state.setAudioOnTap,
          ),
          // AGENT C: reciter list goes here
          _ReciterSection(
            future: _reciterFuture,
            state: state,
            refreshing: _refreshing,
            onRefresh: _refresh,
          ),
        ],
      ),
    );
  }
}

class _ReciterSection extends StatelessWidget {
  final Future<List<Reciter>>? future;
  final AppStateNotifier state;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _ReciterSection({
    required this.future,
    required this.state,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reciter>>(
      future: future,
      builder: (context, snap) {
        final reciters = snap.data ?? const <Reciter>[];
        final selectedId = state.selectedReciterId ?? kDefaultReciterId;
        Reciter? selected;
        for (final r in reciters) {
          if (r.id == selectedId) {
            selected = r;
            break;
          }
        }
        final status = ReciterCatalog().status;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Reciter'),
              subtitle: Text(
                selected != null
                    ? '${selected.displayName} (${selected.provider})'
                    : 'Loading…',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: snap.connectionState == ConnectionState.done
                  ? () async {
                      final picked = await Navigator.of(context).push<Reciter>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReciterPickerScreen(reciters: reciters),
                        ),
                      );
                      if (picked != null) state.setReciter(picked.id);
                    }
                  : null,
            ),
            if (selected != null && selected.provider == kProviderAlquranCloud)
              _BitrateRow(state: state, selected: selected, reciters: reciters),
            ListTile(
              dense: true,
              title: Text(
                _statusLine(status, snap, reciters),
                style: TextStyle(
                  color: status.lastError != null
                      ? Colors.red.shade700
                      : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              trailing: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh reciter list',
                      onPressed: onRefresh,
                    ),
            ),
          ],
        );
      },
    );
  }

  String _statusLine(
    CatalogStatus status,
    AsyncSnapshot<List<Reciter>> snap,
    List<Reciter> reciters,
  ) {
    if (snap.connectionState != ConnectionState.done) {
      return 'Loading reciters…';
    }
    if (status.lastError != null) {
      return 'Network error — using ${status.fromFallback ? "offline defaults" : "cache"} (${reciters.length})';
    }
    if (status.fromFallback) {
      return 'Using offline default reciters (${reciters.length}).';
    }
    if (status.fromCache) {
      return 'Loaded ${reciters.length} reciters from cache.';
    }
    return 'Loaded ${reciters.length} reciters.';
  }
}

class _BitrateRow extends StatelessWidget {
  final AppStateNotifier state;
  final Reciter selected;
  final List<Reciter> reciters;

  const _BitrateRow({
    required this.state,
    required this.selected,
    required this.reciters,
  });

  @override
  Widget build(BuildContext context) {
    final currentBr = selected.bitrate ?? 128;
    return ListTile(
      title: const Text('Bitrate'),
      trailing: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 64, label: Text('64k')),
          ButtonSegment(value: 128, label: Text('128k')),
        ],
        selected: {currentBr},
        onSelectionChanged: (s) {
          final next = s.first;
          if (next == currentBr) return;
          // Find sibling reciter at the new bitrate.
          final base = selected.id.split(':').sublist(0, 2).join(':');
          final newId = '$base:$next';
          final exists = reciters.any((r) => r.id == newId);
          if (exists) state.setReciter(newId);
        },
      ),
    );
  }
}

/// Picker — full list with search bar, grouped by language.
class ReciterPickerScreen extends StatefulWidget {
  final List<Reciter> reciters;
  const ReciterPickerScreen({super.key, required this.reciters});

  @override
  State<ReciterPickerScreen> createState() => _ReciterPickerScreenState();
}

class _ReciterPickerScreenState extends State<ReciterPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.reciters
        : widget.reciters.where((r) {
            return r.displayName.toLowerCase().contains(q) ||
                (r.authorAr ?? '').contains(q) ||
                r.provider.toLowerCase().contains(q);
          }).toList();

    // Group by language code, default 'ar' first.
    final groups = <String, List<Reciter>>{};
    for (final r in filtered) {
      final lang = r.languageEn ?? 'other';
      groups.putIfAbsent(lang, () => []).add(r);
    }
    final langKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'ar') return -1;
        if (b == 'ar') return 1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Choose reciter')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search reciters',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final lang in langKeys) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _languageLabel(lang),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ),
                  for (final r in groups[lang]!)
                    ListTile(
                      title: Text(r.displayName),
                      subtitle: Text(_subtitle(r)),
                      trailing: Text(
                        r.authorAr ?? '',
                        style: const TextStyle(
                          fontFamily: 'IndopakNastaleeq',
                          fontSize: 18,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(r),
                    ),
                ],
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No reciters match.')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String lang) {
    switch (lang) {
      case 'ar':
        return 'Arabic';
      case 'en':
        return 'English';
      default:
        return lang.isEmpty ? 'Other' : lang.toUpperCase();
    }
  }

  String _subtitle(Reciter r) {
    final parts = <String>[r.provider];
    if (r.bitrate != null) parts.add('${r.bitrate}kbps');
    return parts.join(' · ');
  }
}
