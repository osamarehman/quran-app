/// Continuous per-ayah audio playback (v0.2 Stage 1C, expanded for v0.7).
///
/// Singleton wrapping just_audio. Builds a ConcatenatingAudioSource that
/// grows ahead of playback so successive ayahs are gapless. Tapping a new
/// ayah replaces the queue starting at that ayah; pause/resume keep the
/// queue. Quran.com per-ayah URL resolution is cached. alquran.cloud 404s
/// transparently fall back through alternate bitrates.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../data/mushaf_db.dart';
import '../data/quran_metadata.dart';
import '../state/app_state.dart';
import 'reciter_catalog.dart';

typedef AyahPos = ({int surah, int ayah});

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  static const int _resolvedUrlCacheCap = 256;

  final AudioPlayer _player = AudioPlayer();
  http.Client _client = http.Client();
  final ReciterCatalog _catalog = ReciterCatalog();

  final LinkedHashMap<String, String> _resolvedUrlCache =
      LinkedHashMap<String, String>();

  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<AyahPos?> nowPlaying = ValueNotifier<AyahPos?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  ConcatenatingAudioSource? _queue;
  final List<AyahPos> _queueAyahs = [];
  MushafDb? _activeDb;
  Reciter? _activeReciter;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<PlayerState>? _stateSub;
  // Lookahead beyond currently-playing index. 1 means "load one ayah ahead";
  // ConcatenatingAudioSource handles the gapless transition itself.
  static const int _lookahead = 2;

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerState => _player.playerStateStream;

  @visibleForTesting
  void debugConfigureForTest({required http.Client client}) {
    _client = client;
    _resolvedUrlCache.clear();
  }

  Future<Reciter> resolveReciter(AppStateNotifier state) async {
    final id = state.selectedReciterId ?? kDefaultReciterId;
    final r = await _catalog.byId(id);
    if (r != null) return r;
    final fallback = await _catalog.byId(kDefaultReciterId);
    return fallback ?? defaultReciters().first;
  }

  /// Plays continuously starting at ([surah], [ayah]) and advancing through
  /// subsequent ayahs. If a queue is already running, it's replaced.
  Future<void> playFromAyah(
    MushafDb db,
    Reciter reciter,
    int surah,
    int ayah,
  ) async {
    _activeDb = db;
    _activeReciter = reciter;

    await _resetQueue();

    final firstSrc = await _buildSourceFor(reciter, surah, ayah);
    if (firstSrc == null) {
      lastError.value ??=
          'Could not resolve audio for ${reciter.displayName} at $surah:$ayah';
      return;
    }

    _queueAyahs.add((surah: surah, ayah: ayah));
    _queue = ConcatenatingAudioSource(children: [firstSrc]);

    try {
      await _player.setAudioSource(_queue!);
    } on PlayerException catch (e) {
      lastError.value = 'Playback failed: ${e.message ?? e.code}';
      return;
    } on PlayerInterruptedException {
      return;
    }

    _indexSub = _player.currentIndexStream.listen(_onIndexChanged);
    _stateSub = _player.playerStateStream.listen(_onPlayerStateChanged);

    nowPlaying.value = (surah: surah, ayah: ayah);
    await _ensureLookahead(0);
    await _player.play();
  }

  /// Plays continuously starting at the first ayah on [pageNumber].
  Future<void> playFromPage(
    MushafDb db,
    Reciter reciter,
    int pageNumber,
  ) async {
    final pos = await db.firstAyahOfPage(pageNumber);
    if (pos == null) {
      lastError.value = 'Page $pageNumber has no ayah to play';
      return;
    }
    await playFromAyah(db, reciter, pos.surah, pos.ayah);
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() async {
    if (_queue == null) return;
    await _player.play();
  }

  Future<void> togglePause() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_queue != null) {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _resetQueue();
  }

  void _onIndexChanged(int? idx) {
    if (idx == null || idx >= _queueAyahs.length) return;
    nowPlaying.value = _queueAyahs[idx];
    _ensureLookahead(idx);
  }

  void _onPlayerStateChanged(PlayerState s) {
    isPlaying.value = s.playing;
    if (s.processingState == ProcessingState.completed) {
      // End of queue (e.g. last ayah of Quran). Reset state.
      _resetQueue();
    }
  }

  Future<void> _ensureLookahead(int currentIdx) async {
    final db = _activeDb;
    final reciter = _activeReciter;
    final queue = _queue;
    if (db == null || reciter == null || queue == null) return;

    while (_queueAyahs.length - currentIdx <= _lookahead) {
      final last = _queueAyahs.last;
      final next = _nextAyah(last.surah, last.ayah);
      if (next == null) return;
      final src = await _buildSourceFor(reciter, next.surah, next.ayah);
      if (src == null) return;
      _queueAyahs.add(next);
      try {
        await queue.add(src);
      } on PlayerException {
        return;
      } on PlayerInterruptedException {
        return;
      }
    }
  }

  AyahPos? _nextAyah(int surah, int ayah) {
    if (surah < 1 || surah > kSurahAyahCounts.length) return null;
    final maxAyah = kSurahAyahCounts[surah - 1];
    if (ayah < maxAyah) return (surah: surah, ayah: ayah + 1);
    if (surah < 114) return (surah: surah + 1, ayah: 1);
    return null;
  }

  Future<AudioSource?> _buildSourceFor(
    Reciter reciter,
    int surah,
    int ayah,
  ) async {
    final globalIdx = await _activeDb?.globalAyahIndex(surah, ayah);
    if (globalIdx == null) {
      lastError.value = 'Ayah $surah:$ayah not in DB';
      return null;
    }
    final url = await _resolveUrl(reciter, globalIdx, surah, ayah);
    if (url == null) return null;
    return AudioSource.uri(Uri.parse(url));
  }

  Future<void> _resetQueue() async {
    await _indexSub?.cancel();
    _indexSub = null;
    await _stateSub?.cancel();
    _stateSub = null;
    try {
      await _player.stop();
    } catch (_) {}
    _queue = null;
    _queueAyahs.clear();
    nowPlaying.value = null;
    isPlaying.value = false;
  }

  /// Single-shot ayah play (legacy entry point — now delegates to the
  /// continuous queue so taps "play this ayah and continue").
  Future<void> playAyah(MushafDb db, Reciter reciter, int surah, int ayah) =>
      playFromAyah(db, reciter, surah, ayah);

  @visibleForTesting
  Future<String?> resolveUrlForTest(
    Reciter reciter,
    int globalIdx,
    int surah,
    int ayah,
  ) =>
      _resolveUrl(reciter, globalIdx, surah, ayah);

  Future<String?> _resolveUrl(
    Reciter reciter,
    int globalIdx,
    int surah,
    int ayah,
  ) async {
    if (!reciter.requiresMetadataFetch) {
      return reciter.urlBuilder(globalIdx).toString();
    }

    final cacheKey = '${reciter.id}:$surah:$ayah';
    final cached = _resolvedUrlCache.remove(cacheKey);
    if (cached != null) {
      _resolvedUrlCache[cacheKey] = cached;
      return cached;
    }

    final recId = reciter.providerRecitationId;
    if (recId == null) {
      lastError.value = 'Reciter ${reciter.displayName} missing provider id';
      return null;
    }

    final metaUrl = Uri.parse(
      'https://api.quran.com/api/v4/recitations/$recId/by_ayah_key/$surah:$ayah',
    );
    try {
      final res = await _client
          .get(metaUrl)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        lastError.value = 'Quran.com returned ${res.statusCode} for $surah:$ayah';
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final audioFiles = body['audio_files'];
      String? audioPath;
      if (audioFiles is List && audioFiles.isNotEmpty) {
        final first = audioFiles.first;
        if (first is Map) audioPath = first['url'] as String?;
      } else if (body['audio_file'] is Map) {
        audioPath = (body['audio_file'] as Map)['url'] as String?;
      }
      if (audioPath == null) {
        lastError.value = 'Quran.com response had no audio url';
        return null;
      }
      final full = audioPath.startsWith('http')
          ? audioPath
          : 'https://verses.quran.com/$audioPath';
      _putCache(cacheKey, full);
      return full;
    } on TimeoutException {
      lastError.value = 'Quran.com timed out';
      return null;
    } on SocketException catch (e) {
      lastError.value = 'Network error: ${e.message}';
      return null;
    } on FormatException catch (e) {
      lastError.value = 'Quran.com returned invalid JSON: ${e.message}';
      return null;
    }
  }

  void _putCache(String key, String url) {
    _resolvedUrlCache[key] = url;
    while (_resolvedUrlCache.length > _resolvedUrlCacheCap) {
      _resolvedUrlCache.remove(_resolvedUrlCache.keys.first);
    }
  }

  /// Convenience handler intended for `MushafPage.onWordTap`. Starts
  /// continuous playback from the tapped ayah onward; reuses any active
  /// reciter; surfaces errors via snackbar.
  Future<void> handleWordTap(
    BuildContext context,
    MushafDb db,
    AppStateNotifier state,
    MushafWord word,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final reciter = await resolveReciter(state);
    await playFromAyah(db, reciter, word.surah, word.ayah);
    final err = lastError.value;
    if (err != null && messenger != null) {
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(err),
      ));
    }
  }

  Future<void> dispose() async {
    await _resetQueue();
    await _player.dispose();
  }
}
