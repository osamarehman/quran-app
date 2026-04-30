/// Per-ayah audio playback (v0.2 Stage 1C).
///
/// Singleton wrapping just_audio. Resolves the global ayah index from
/// MushafDb, looks up the URL via the active Reciter, and plays.
library;

import 'dart:async';
import 'dart:convert';

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

  final AudioPlayer _player = AudioPlayer();
  http.Client _client = http.Client();
  final ReciterCatalog _catalog = ReciterCatalog();

  // Cache resolved Quran.com URLs so we don't re-hit the metadata API on
  // every replay of the same ayah.
  final Map<String, String> _resolvedUrlCache = {};

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
      final url = await _resolveUrl(reciter, globalIdx);
      if (url == null) {
        lastError.value = 'Could not resolve audio URL for ${reciter.displayName}';
        return;
      }
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
      lastError.value = null;
    } catch (e) {
      lastError.value = 'Audio error: $e';
    }
  }

  Future<String?> _resolveUrl(Reciter reciter, int globalIdx) async {
    if (!reciter.requiresMetadataFetch) {
      return reciter.urlBuilder(globalIdx).toString();
    }
    final cacheKey = '${reciter.id}:$globalIdx';
    final cached = _resolvedUrlCache[cacheKey];
    if (cached != null) return cached;

    // Quran.com per-ayah lookup. The endpoint
    // /api/v4/recitations/{id}/by_ayah_key/{key} returns
    // { "audio_files": [ { "url": "audio/.../001001.mp3", ... } ] }
    // where url is relative to https://verses.quran.com/.
    final recId = reciter.providerRecitationId;
    if (recId == null) return null;
    // Convert globalIdx → ayah_key (e.g. "1:1"). This requires DB lookup,
    // but we already accepted globalIdx as input. Use the metadata URL
    // pattern emitted by Reciter.quranCom which embeds globalIdx.
    final metaUrl = reciter.urlBuilder(globalIdx);
    try {
      final res =
          await _client.get(metaUrl).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final audioFiles = body['audio_files'];
      String? audioPath;
      if (audioFiles is List && audioFiles.isNotEmpty) {
        final first = audioFiles.first;
        if (first is Map) audioPath = first['url'] as String?;
      } else if (body['audio_file'] is Map) {
        audioPath = (body['audio_file'] as Map)['url'] as String?;
      }
      if (audioPath == null) return null;
      final full = audioPath.startsWith('http')
          ? audioPath
          : 'https://verses.quran.com/$audioPath';
      _resolvedUrlCache[cacheKey] = full;
      return full;
    } catch (_) {
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
