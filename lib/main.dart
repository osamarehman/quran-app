import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushaf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        scaffoldBackgroundColor: const Color(0xFFFAF7F0),
        useMaterial3: true,
      ),
      home: const MushafHome(),
    );
  }
}

class MushafHome extends StatefulWidget {
  const MushafHome({super.key});

  @override
  State<MushafHome> createState() => _MushafHomeState();
}

class _MushafHomeState extends State<MushafHome> {
  late final Future<MushafDb> _dbFuture = MushafDb.open();
  int _pageNumber = 1;
  static const int _totalPages = 610;

  void _go(int delta) {
    final next = _pageNumber + delta;
    if (next < 1 || next > _totalPages) return;
    setState(() => _pageNumber = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<MushafDb>(
          future: _dbFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to open mushaf DB:\n${snap.error}'),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 250) {
                  _go(-1);
                } else if (v < -250) {
                  _go(1);
                }
              },
              child: Column(
                children: [
                  _PageHeader(
                    pageNumber: _pageNumber,
                    totalPages: _totalPages,
                    onPrev: _pageNumber > 1 ? () => _go(-1) : null,
                    onNext: _pageNumber < _totalPages ? () => _go(1) : null,
                  ),
                  Expanded(
                    child: MushafPage(
                      db: snap.data!,
                      pageNumber: _pageNumber,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PageHeader({
    required this.pageNumber,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
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

class MushafDb {
  final Database layoutDb;
  final Database wordsDb;

  MushafDb._(this.layoutDb, this.wordsDb);

  static Future<MushafDb> open() async {
    debugPrint('[MushafDb] opening layout');
    final layout = await _openAsset('assets/data/qudratullah-indopak-15-lines.db');
    debugPrint('[MushafDb] layout opened, sanity probe...');
    final probe = await layout.rawQuery('SELECT COUNT(*) AS c FROM pages');
    debugPrint('[MushafDb] layout probe: ${probe.first['c']} pages');
    debugPrint('[MushafDb] opening words');
    final words = await _openAsset('assets/data/words-indopak-nastaleeq.db');
    debugPrint('[MushafDb] words opened');
    return MushafDb._(layout, words);
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
    debugPrint('[MushafDb] getPage($pageNumber) starting');
    final rows = await layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    debugPrint('[MushafDb] getPage($pageNumber) -> ${rows.length} rows');
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

  Future<List<MushafWord>> getWords(int firstId, int lastId) async {
    debugPrint('[MushafDb] getWords($firstId..$lastId) starting');
    final rows = await wordsDb.query(
      'words',
      where: 'id BETWEEN ? AND ?',
      whereArgs: [firstId, lastId],
      orderBy: 'id ASC',
    );
    debugPrint('[MushafDb] getWords($firstId..$lastId) -> ${rows.length} rows');
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
}

class _PageData {
  final List<MushafLine> lines;
  final Map<int, List<MushafWord>> wordsByLine;
  _PageData(this.lines, this.wordsByLine);
}

class MushafPage extends StatefulWidget {
  final MushafDb db;
  final int pageNumber;

  const MushafPage({super.key, required this.db, required this.pageNumber});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late Future<_PageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _data = _load();
    }
  }

  Future<_PageData> _load() async {
    debugPrint('[MushafPage] loading page ${widget.pageNumber}');
    final lines = await widget.db.getPage(widget.pageNumber);
    debugPrint('[MushafPage] got ${lines.length} lines');
    final wordsByLine = <int, List<MushafWord>>{};
    for (final l in lines) {
      if (l.firstWordId != null && l.lastWordId != null) {
        final words = await widget.db.getWords(l.firstWordId!, l.lastWordId!);
        debugPrint('[MushafPage] line ${l.lineNumber} (${l.lineType}): ${words.length} words');
        wordsByLine[l.lineNumber] = words;
      }
    }
    return _PageData(lines, wordsByLine);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PageData>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Page load failed:\n${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (final l in data.lines)
                Expanded(
                  child: MushafLineWidget(
                    line: l,
                    words: data.wordsByLine[l.lineNumber] ?? const [],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class MushafLineWidget extends StatelessWidget {
  final MushafLine line;
  final List<MushafWord> words;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    switch (line.lineType) {
      case 'surah_name':
        return _SurahNameLine(surahNumber: line.surahNumber ?? 0);
      case 'basmallah':
        return const _BasmallahLine();
      case 'ayah':
      default:
        return _AyahLine(words: words, isCentered: line.isCentered);
    }
  }
}

const _baseFontSize = 28.0;
const _baseTextStyle = TextStyle(
  fontFamily: 'IndopakNastaleeq',
  fontSize: _baseFontSize,
  height: 1.0,
  color: Color(0xFF111111),
);
// Minimum visual gap between words even when a line is at full font size.
// Without this, spaceBetween can produce zero-gap lines that read as run-on.
const _minWordGap = 4.0;

class _AyahLine extends StatelessWidget {
  final List<MushafWord> words;
  final bool isCentered;

  const _AyahLine({required this.words, required this.isCentered});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _fitStyle(words, constraints.maxWidth);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: isCentered
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              for (final w in words)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onWordTap(context, w),
                  child: Text(w.text, style: style),
                ),
            ],
          ),
        );
      },
    );
  }

  // Returns a TextStyle whose fontSize is scaled down from _baseFontSize so
  // that the words fit edge-to-edge with at least _minWordGap between each.
  // No-op when the line already fits at base size.
  static TextStyle _fitStyle(List<MushafWord> words, double maxWidth) {
    if (words.length < 2 || maxWidth <= 0) return _baseTextStyle;
    double totalWordWidth = 0;
    for (final w in words) {
      final tp = TextPainter(
        text: TextSpan(text: w.text, style: _baseTextStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      totalWordWidth += tp.size.width;
    }
    final neededWidth = totalWordWidth + _minWordGap * (words.length - 1);
    if (neededWidth <= maxWidth) return _baseTextStyle;
    final scale = maxWidth / neededWidth;
    return _baseTextStyle.copyWith(fontSize: _baseFontSize * scale);
  }

  void _onWordTap(BuildContext context, MushafWord w) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 800),
        content: Text('${w.surah}:${w.ayah} word ${w.wordIndex} — ${w.text}'),
      ),
    );
  }
}

class _SurahNameLine extends StatelessWidget {
  final int surahNumber;
  const _SurahNameLine({required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Text(
          'سُورَة $surahNumber',
          style: const TextStyle(
            fontFamily: 'IndopakNastaleeq',
            fontSize: 22,
            color: Color(0xFF222222),
          ),
        ),
      ),
    );
  }
}

class _BasmallahLine extends StatelessWidget {
  const _BasmallahLine();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِیْمِ',
        style: TextStyle(
          fontFamily: 'IndopakNastaleeq',
          fontSize: 26,
          color: Color(0xFF111111),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
