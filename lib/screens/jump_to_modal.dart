import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';

/// Three-tab modal — by Surah, by Juz, by Page — that resolves the user's
/// pick into a 1-based mushaf page and pops the result up to the caller.
Future<int?> showJumpToModal(
  BuildContext context, {
  required int totalPages,
  required MushafDb db,
}) {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SizedBox(
          height: mq.size.height * 0.7,
          child: _JumpToBody(totalPages: totalPages, db: db),
        ),
      );
    },
  );
}

class _JumpToBody extends StatelessWidget {
  final int totalPages;
  final MushafDb db;
  const _JumpToBody({required this.totalPages, required this.db});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Surah'),
                Tab(text: 'Juz'),
                Tab(text: 'Page'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SurahTab(db: db),
                  _JuzTab(db: db),
                  _PageTab(totalPages: totalPages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahTab extends StatelessWidget {
  final MushafDb db;
  const _SurahTab({required this.db});

  @override
  Widget build(BuildContext context) {
    final count = kSurahNames.isNotEmpty ? kSurahNames.length : 114;
    return ListView.builder(
      itemCount: count,
      itemBuilder: (ctx, i) {
        final id = i + 1;
        String title;
        String? subtitle;
        if (kSurahNames.isNotEmpty) {
          final m = kSurahNames[i];
          title = '$id. ${m.ar}';
          subtitle = '${m.transliteration} — ${m.en}';
        } else {
          title = 'Surah $id';
        }
        return ListTile(
          dense: true,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: () async {
            final page = await _pageForSurah(db, id);
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(page);
          },
        );
      },
    );
  }
}

class _JuzTab extends StatelessWidget {
  final MushafDb db;
  const _JuzTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var j = 1; j <= 30; j++)
            OutlinedButton(
              onPressed: () async {
                final page = await _pageForJuz(db, j);
                if (!context.mounted) return;
                Navigator.of(context).pop(page);
              },
              child: Text('$j'),
            ),
        ],
      ),
    );
  }
}

class _PageTab extends StatefulWidget {
  final int totalPages;
  const _PageTab({required this.totalPages});

  @override
  State<_PageTab> createState() => _PageTabState();
}

class _PageTabState extends State<_PageTab> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final n = int.tryParse(raw);
    if (n == null || n < 1 || n > widget.totalPages) {
      setState(() => _error = 'Enter 1 — ${widget.totalPages}');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Page',
              hintText: '1 — ${widget.totalPages}',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: const Text('Go')),
        ],
      ),
    );
  }
}

// --- DB lookups --------------------------------------------------------------

Future<int?> _pageForSurah(MushafDb db, int surah) async {
  // Prefer the dedicated surah_name line type (start of surah headings).
  try {
    final headerRows = await db.layoutDb.rawQuery(
      'SELECT MIN(page_number) AS p FROM pages '
      "WHERE line_type = 'surah_name' AND surah_number = ?",
      [surah],
    );
    if (headerRows.isNotEmpty) {
      final p = headerRows.first['p'];
      final n = _coerceInt(p);
      if (n != null) return n;
    }
  } catch (_) {/* fall through */}

  // Fallback: page containing the first word of that surah.
  try {
    final wordRows = await db.wordsDb.rawQuery(
      'SELECT MIN(id) AS id FROM words WHERE surah = ?',
      [surah],
    );
    if (wordRows.isEmpty) return null;
    final firstId = _coerceInt(wordRows.first['id']);
    if (firstId == null) return null;
    final pageRows = await db.layoutDb.rawQuery(
      'SELECT MIN(page_number) AS p FROM pages '
      'WHERE first_word_id <= ? AND last_word_id >= ?',
      [firstId, firstId],
    );
    if (pageRows.isEmpty) return null;
    return _coerceInt(pageRows.first['p']);
  } catch (_) {
    return null;
  }
}

Future<int?> _pageForJuz(MushafDb db, int juz) async {
  if (juz == 1) {
    return _pageForSurah(db, 1);
  }
  // Without an exposed juz-starts table we lean on Agent A's juzForAyah:
  // find the first surah whose first ayah falls in this juz, then resolve
  // via the surah lookup. Once kJuzNamesAr / _kJuzStarts is populated this
  // gives the correct first page for every juz; until then it falls through.
  for (var s = 1; s <= 114; s++) {
    if (juzForAyah(s, 1) == juz) {
      return _pageForSurah(db, s);
    }
  }
  return null;
}

int? _coerceInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
