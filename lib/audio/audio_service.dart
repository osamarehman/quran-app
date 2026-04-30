/// Per-ayah audio playback (v0.2 Stage 1C).
///
/// Singleton wrapping just_audio. Resolves the global ayah index from
/// MushafDb, looks up the URL via the active Reciter, and plays.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../data/mushaf_db.dart';
import '../state/app_state.dart';
import 'reciter_catalog.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  static const int _resolvedUrlCacheCap = 256;

  final AudioPlayer _player = AudioPlayer();
  http.Client _client = http.Client();
  final ReciterCatalog _catalog = ReciterCatalog();

  // Bounded LRU of resolved Quran.com URLs so we don't re-hit the metadata
  // API on every replay. LinkedHashMap preserves insertion order; we evict
  // the oldest entry when over cap.
  final LinkedHashMap<String, String> _resolvedUrlCache =
      LinkedHashMap<String, String>();

  // Last error surfaced to UI as a snackbar.
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerState => _player.playerStateStream;

  @visibleForTesting
  void debugConfigureForTest({required http.Client client}) {
    _client = client;
    _resolvedUrlCache.clear();
  }

  /// Resolves the active reciter from AppState, falling back to default.
  Future<Reciter> resolveReciter(AppStateNotifier state) async {
    final id = state.selectedReciterId ?? kDefaultReciterId;
    final r = await _catalog.byId(id);
    if (r != null) return r;
    // Fallback: pick the first default.
    final fallback = await _catalog.byId(kDefaultReciterId);
    return fallback ?? defaultReciters().first;
  }

  /// Plays a single ayah for the currently-selected reciter.
  Future<void> playAyah(MushafDb db, Reciter reciter, int surah, int ayah) async {
    final globalIdx = await db.globalAyahIndex(surah, ayah);
    if (globalIdx == null) {
      lastError.value = 'Ayah $surah:$ayah not in DB';
      return;
    }
    try {
      final url = await _resolveUrl(reciter, globalIdx, surah, ayah);
      if (url == null) {
        // _resolveUrl may have already populated lastError with the cause.
        lastError.value ??=
            'Could not resolve audio URL for ${reciter.displayName}';
        return;
      }
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      lastError.value = null;
    } on PlayerException catch (e) {
      lastError.value = 'Playback failed: ${e.message ?? e.code}';
    } on PlayerInterruptedException {
      // Replaced by another setUrl/play — not user-facing.
    } on SocketException catch (e) {
      lastError.value = 'Network error: ${e.message}';
    }
  }

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
    // Cache by ayah_key — replays of the same ayah for the same reciter
    // shouldn't re-hit the metadata endpoint.
    final cacheKey = '${reciter.id}:$surah:$ayah';
    final cached = _resolvedUrlCache.remove(cacheKey);
    if (cached != null) {
      _resolvedUrlCache[cacheKey] = cached; // bump to most-recent
      return cached;
    }

    final recId = reciter.providerRecitationId;
    if (recId == null) {
      lastError.value = 'Reciter ${reciter.displayName} missing provider id';
      return null;
    }

    // Quran.com per-ayah lookup. Path is /by_ayah_key/{surah}:{ayah}
    // (NOT global index). Response shape:
    //   { "audio_files": [ { "url": "audio/.../001001.mp3", ... } ] }
    // where url is relative to https://verses.quran.com/.
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
      _resolvedUrlCache[cacheKey] = full;
      while (_resolvedUrlCache.length > _resolvedUrlCacheCap) {
        _resolvedUrlCache.remove(_resolvedUrlCache.keys.first);
      }
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

  Future<void> stop() => _player.stop();
  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  /// Convenience handler intended for `MushafPage.onWordTap`.
  /// Resolves the active reciter, plays the ayah, surfaces errors via snackbar.
  Future<void> handleWordTap(
    BuildContext context,
    MushafDb db,
    AppStateNotifier state,
    MushafWord word,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final reciter = await resolveReciter(state);
    await playAyah(db, reciter, word.surah, word.ayah);
    final err = lastError.value;
    if (err != null && messenger != null) {
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(err),
      ));
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
