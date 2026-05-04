import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MushafLine {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;

  const MushafLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahNumber,
  });
}

class MushafWord {
  final int id;
  final int surah;
  final int ayah;
  final int wordIndex;
  final String text;

  const MushafWord({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.text,
  });
}

class MushafEdition {
  final String id;
  final String label;
  final String layoutAsset;
  final int totalPages;
  final int linesPerPage;

  const MushafEdition({
    required this.id,
    required this.label,
    required this.layoutAsset,
    required this.totalPages,
    required this.linesPerPage,
  });

  static const fifteenLine = MushafEdition(
    id: '15-line-qudratullah',
    label: '15 lines (Qudratullah)',
    layoutAsset: 'assets/data/qudratullah-indopak-15-lines.db',
    totalPages: 610,
    linesPerPage: 15,
  );

  static const sixteenLine = MushafEdition(
    id: '16-line-taj',
    label: '16 lines (Taj)',
    layoutAsset: 'assets/data/taj-indopak-16-lines.db',
    totalPages: 548,
    linesPerPage: 16,
  );

  static const all = <MushafEdition>[fifteenLine, sixteenLine];
}

class MushafDb {
  final MushafEdition edition;
  final Database layoutDb;
  final Database wordsDb;
  final Database versesDb;

  MushafDb._(this.edition, this.layoutDb, this.wordsDb, this.versesDb);

  static Future<MushafDb> open({MushafEdition edition = MushafEdition.fifteenLine}) async {
    final layout = await _openAsset(edition.layoutAsset);
    final words = await _openAsset('assets/data/words-indopak-nastaleeq.db');
    final verses = await _openAsset('assets/data/verses-indopak-nastaleeq.db');
    return MushafDb._(edition, layout, words, verses);
  }

  Future<void> close() async {
    await layoutDb.close();
    await wordsDb.close();
    await versesDb.close();
  }

  static Future<Database> _openAsset(String assetPath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dest = File(p.join(docs.path, p.basename(assetPath)));
    if (!await dest.exists()) {
      final data = await rootBundle.load(assetPath);
      await dest.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return openDatabase(dest.path);
  }

  Future<List<MushafLine>> getPage(int pageNumber) async {
    final rows = await layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    return [
      for (final r in rows)
        MushafLine(
          pageNumber: _intRequired(r['page_number']),
          lineNumber: _intRequired(r['line_number']),
          lineType: r['line_type'] as String,
          isCentered: _intRequired(r['is_centered']) == 1,
          firstWordId: _intOrNull(r['first_word_id']),
          lastWordId: _intOrNull(r['last_word_id']),
          surahNumber: _intOrNull(r['surah_number']),
        ),
    ];
  }

  Future<List<MushafWord>> getWords(int firstId, int lastId) async {
    final rows = await wordsDb.query(
      'words',
      where: 'id BETWEEN ? AND ?',
      whereArgs: [firstId, lastId],
      orderBy: 'id ASC',
    );
    return [
      for (final r in rows)
        MushafWord(
          id: r['id'] as int,
          surah: r['surah'] as int,
          ayah: r['ayah'] as int,
          wordIndex: r['word'] as int,
          text: r['text'] as String,
        ),
    ];
  }

  /// First ayah position on [pageNumber] — the (surah, ayah) of the first
  /// word on the topmost word-bearing line. Returns null for pages that hold
  /// only ornamental rows (impossible in practice for the bundled layouts).
  Future<({int surah, int ayah})?> firstAyahOfPage(int pageNumber) async {
    final lines = await getPage(pageNumber);
    for (final l in lines) {
      if (l.firstWordId != null && l.lastWordId != null) {
        final words = await getWords(l.firstWordId!, l.lastWordId!);
        if (words.isNotEmpty) {
          return (surah: words.first.surah, ayah: words.first.ayah);
        }
      }
    }
    return null;
  }

  /// Resolve a (surah, ayah) pair to its global ayah index (1..6236), used by
  /// alquran.cloud's audio CDN URL pattern.
  Future<int?> globalAyahIndex(int surah, int ayah) async {
    final rows = await versesDb.query(
      'verses',
      columns: ['id'],
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _intRequired(rows.first['id']);
  }

  // SQLite's INTEGER affinity allows empty-string storage on absent values, so
  // null-or-int columns can come back as "". Coerce defensively.
  static int? _intOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return v.isEmpty ? null : int.tryParse(v);
    return null;
  }

  static int _intRequired(Object? v) {
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    throw FormatException('expected int, got ${v.runtimeType}: $v');
  }
}

// Used in flutter_test which needs a deterministic ffi backend.
@visibleForTesting
void initSqfliteForTesting() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
