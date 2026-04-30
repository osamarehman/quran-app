/// Multi-CDN reciter catalog. Merges alquran.cloud (direct CDN URLs) and
/// Quran.com (per-ayah metadata fetch). Cached to disk under the app docs
/// dir as `reciter_catalog.json`, re-fetched on demand or after 7 days.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String kProviderAlquranCloud = 'alquran.cloud';
const String kProviderQuranCom = 'quran.com';

/// alquran.cloud CDN URL pattern. The `globalAyahIndex` is 1..6236 matching
/// the canonical mushaf numbering.
String alquranCloudAudioUrl({
  required String editionSlug,
  required int bitrate,
  required int globalAyahIndex,
}) =>
    'https://cdn.islamic.network/quran/audio/$bitrate/$editionSlug/$globalAyahIndex.mp3';

/// A reciter entry in the merged catalog. `urlBuilder` accepts the global
/// ayah index (1..6236) and returns the audio URL — for providers that need
/// a metadata fetch first (Quran.com), `requiresMetadataFetch` is true and
/// the URL is a placeholder that AudioService resolves at playback time.
class Reciter {
  final String id;
  final String displayName;
  final String? authorAr;
  final String? languageEn;
  final String? languageAr;
  final String provider;
  final int? bitrate;
  final Uri Function(int globalAyahIndex) urlBuilder;
  final bool requiresMetadataFetch;
  final String? providerRecitationId;

  const Reciter({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.urlBuilder,
    this.authorAr,
    this.languageEn,
    this.languageAr,
    this.bitrate,
    this.requiresMetadataFetch = false,
    this.providerRecitationId,
  });

  /// Builds a reciter for the alquran.cloud CDN.
  factory Reciter.alquranCloud({
    required String editionSlug,
    required String displayName,
    required int bitrate,
    String? authorAr,
    String? languageEn,
    String? languageAr,
  }) {
    return Reciter(
      id: 'alquran:$editionSlug:$bitrate',
      displayName: displayName,
      provider: kProviderAlquranCloud,
      bitrate: bitrate,
      authorAr: authorAr,
      languageEn: languageEn,
      languageAr: languageAr,
      urlBuilder: (globalAyahIndex) => Uri.parse(
        alquranCloudAudioUrl(
          editionSlug: editionSlug,
          bitrate: bitrate,
          globalAyahIndex: globalAyahIndex,
        ),
      ),
    );
  }

  /// Builds a reciter for Quran.com. Per-ayah audio requires a metadata
  /// fetch — `urlBuilder` returns the metadata endpoint as a placeholder;
  /// AudioService resolves the real MP3 URL at playback time.
  factory Reciter.quranCom({
    required int recitationId,
    required String displayName,
    String? authorAr,
    String? languageEn,
    String? style,
  }) {
    return Reciter(
      id: 'quran-com:$recitationId',
      displayName: (style != null && style.isNotEmpty)
          ? '$displayName ($style)'
          : displayName,
      provider: kProviderQuranCom,
      authorAr: authorAr,
      languageEn: languageEn,
      requiresMetadataFetch: true,
      providerRecitationId: recitationId.toString(),
      // Built at playback time from (surah, ayah) — see AudioService._resolveUrl.
      // urlBuilder is provided so the type stays uniform; the path itself is
      // not the real audio endpoint.
      urlBuilder: (globalAyahIndex) => Uri.parse(
        'https://api.quran.com/api/v4/recitations/$recitationId/by_ayah_key/$globalAyahIndex',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'authorAr': authorAr,
        'languageEn': languageEn,
        'languageAr': languageAr,
        'provider': provider,
        'bitrate': bitrate,
        'requiresMetadataFetch': requiresMetadataFetch,
        'providerRecitationId': providerRecitationId,
      };

  /// Reconstructs from cached JSON, re-deriving urlBuilder from id+provider.
  static Reciter? fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as String?;
    final id = json['id'] as String?;
    final displayName = json['displayName'] as String?;
    if (provider == null || id == null || displayName == null) return null;

    switch (provider) {
      case kProviderAlquranCloud:
        // id shape: alquran:{editionSlug}:{bitrate}
        final parts = id.split(':');
        if (parts.length < 3) return null;
        return Reciter.alquranCloud(
          editionSlug: parts.sublist(1, parts.length - 1).join(':'),
          displayName: displayName,
          bitrate: int.tryParse(parts.last) ?? (json['bitrate'] as int? ?? 128),
          authorAr: json['authorAr'] as String?,
          languageEn: json['languageEn'] as String?,
          languageAr: json['languageAr'] as String?,
        );
      case kProviderQuranCom:
        final recId = int.tryParse(json['providerRecitationId'] as String? ?? '');
        if (recId == null) return null;
        return Reciter.quranCom(
          recitationId: recId,
          displayName: displayName,
          authorAr: json['authorAr'] as String?,
          languageEn: json['languageEn'] as String?,
        );
      default:
        return null;
    }
  }
}

/// Default offline-fallback list. Used on first launch when no internet is
/// available — guarantees the app isn't broken in airplane mode.
List<Reciter> defaultReciters() => [
      Reciter.alquranCloud(
        editionSlug: 'ar.alafasy',
        displayName: 'Mishary Alafasy',
        authorAr: 'مشاري العفاسي',
        bitrate: 128,
        languageEn: 'ar',
      ),
      Reciter.alquranCloud(
        editionSlug: 'ar.husary',
        displayName: 'Mahmoud Khalil Al-Husary',
        authorAr: 'محمود خليل الحصري',
        bitrate: 128,
        languageEn: 'ar',
      ),
      Reciter.alquranCloud(
        editionSlug: 'ar.minshawi',
        displayName: 'Mohamed Siddiq al-Minshawi',
        authorAr: 'محمد صديق المنشاوي',
        bitrate: 128,
        languageEn: 'ar',
      ),
    ];

/// The default reciter id used when AppState has none persisted.
const String kDefaultReciterId = 'alquran:ar.alafasy:128';

/// Status of the most recent catalog fetch — surfaced into settings UI.
class CatalogStatus {
  final DateTime? lastFetched;
  final String? lastError;
  final int reciterCount;
  final bool fromCache;
  final bool fromFallback;

  const CatalogStatus({
    required this.lastFetched,
    required this.lastError,
    required this.reciterCount,
    required this.fromCache,
    required this.fromFallback,
  });
}

/// Concrete catalog. Singleton because settings screen + audio service both
/// need to share the same in-memory list and refresh state.
class ReciterCatalog {
  static final ReciterCatalog _instance = ReciterCatalog._();
  factory ReciterCatalog() => _instance;
  ReciterCatalog._();

  // Test-injection seam.
  http.Client _client = http.Client();
  Future<File> Function()? _cacheFileOverride;

  static const Duration cacheMaxAge = Duration(days: 7);
  static const String cacheFileName = 'reciter_catalog.json';

  List<Reciter>? _cached;
  CatalogStatus _status = const CatalogStatus(
    lastFetched: null,
    lastError: null,
    reciterCount: 0,
    fromCache: false,
    fromFallback: false,
  );
  Future<List<Reciter>>? _inFlight;

  CatalogStatus get status => _status;

  /// FOR TESTS ONLY — inject a mock http client and an alternate cache path.
  void debugConfigureForTest({
    required http.Client client,
    required Future<File> Function() cacheFile,
  }) {
    _client = client;
    _cacheFileOverride = cacheFile;
    _cached = null;
    _inFlight = null;
    _status = const CatalogStatus(
      lastFetched: null,
      lastError: null,
      reciterCount: 0,
      fromCache: false,
      fromFallback: false,
    );
  }

  /// Returns the merged, deduped reciter list. Loads from disk cache if
  /// fresh, otherwise fetches and persists. Always succeeds — falls back to
  /// [defaultReciters] on hard failure.
  Future<List<Reciter>> all() {
    if (_cached != null) return Future.value(_cached);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<Reciter?> byId(String id) async {
    final list = await all();
    return list.where((r) => r.id == id).firstOrNull;
  }

  /// Forces a network re-fetch.
  Future<List<Reciter>> refresh() async {
    _cached = null;
    final list = await _fetchAndPersist();
    _cached = list;
    return list;
  }

  Future<List<Reciter>> _load() async {
    try {
      final cacheFile = await _resolveCacheFile();
      if (await cacheFile.exists()) {
        final stat = await cacheFile.stat();
        final parsed = _parseCacheJson(await cacheFile.readAsString());
        if (parsed.isNotEmpty) {
          _cached = parsed;
          _status = CatalogStatus(
            lastFetched: stat.modified,
            lastError: null,
            reciterCount: parsed.length,
            fromCache: true,
            fromFallback: false,
          );
          if (DateTime.now().difference(stat.modified) > cacheMaxAge) {
            unawaited(_fetchAndPersist().catchError((_) => parsed));
          }
          return parsed;
        }
      }
    } catch (_) {
      // fall through to network
    }
    return _fetchAndPersist();
  }

  Future<List<Reciter>> _fetchAndPersist() async {
    try {
      final results = await Future.wait<List<Reciter>>([
        _fetchAlquranCloud().catchError((_) => <Reciter>[]),
        _fetchQuranCom().catchError((_) => <Reciter>[]),
      ]);
      final seen = <String>{};
      final merged = [
        for (final r in [...results[0], ...results[1]])
          if (seen.add(r.id)) r,
      ];
      if (merged.isEmpty) throw StateError('All providers returned empty');
      _cached = merged;
      try {
        final f = await _resolveCacheFile();
        await f.writeAsString(jsonEncode({
          'version': 1,
          'fetchedAt': DateTime.now().toIso8601String(),
          'reciters': [for (final r in merged) r.toJson()],
        }));
      } catch (_) {
        // Cache-write failure is non-fatal.
      }
      _status = CatalogStatus(
        lastFetched: DateTime.now(),
        lastError: null,
        reciterCount: merged.length,
        fromCache: false,
        fromFallback: false,
      );
      return merged;
    } catch (e) {
      final fallback = defaultReciters();
      _cached = fallback;
      _status = CatalogStatus(
        lastFetched: null,
        lastError: e.toString(),
        reciterCount: fallback.length,
        fromCache: false,
        fromFallback: true,
      );
      return fallback;
    }
  }

  Future<List<Reciter>> _fetchAlquranCloud() async {
    final res = await _client
        .get(Uri.parse('https://api.alquran.cloud/v1/edition/format/audio'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw HttpException('alquran.cloud HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List) throw const FormatException('alquran.cloud: data not list');
    final out = <Reciter>[];
    for (final item in data) {
      if (item is! Map) continue;
      final identifier = item['identifier'] as String?;
      final englishName = item['englishName'] as String? ?? identifier;
      final name = item['name'] as String?;
      final language = item['language'] as String?;
      if (identifier == null || englishName == null) continue;
      // Skip versebyverse / non-standard editions if needed — but the API
      // already filters to type=audio. Generate both bitrates.
      for (final br in const [64, 128]) {
        out.add(Reciter.alquranCloud(
          editionSlug: identifier,
          displayName: englishName,
          bitrate: br,
          authorAr: name,
          languageEn: language,
        ));
      }
    }
    return out;
  }

  Future<List<Reciter>> _fetchQuranCom() async {
    final res = await _client
        .get(Uri.parse('https://api.quran.com/api/v4/resources/recitations'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      // Try the legacy /api/v4/recitations as a fallback.
      final res2 = await _client
          .get(Uri.parse('https://api.quran.com/api/v4/recitations'))
          .timeout(const Duration(seconds: 10));
      if (res2.statusCode != 200) {
        throw HttpException('quran.com HTTP ${res2.statusCode}');
      }
      return _parseQuranCom(res2.body);
    }
    return _parseQuranCom(res.body);
  }

  List<Reciter> _parseQuranCom(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final list = (json['recitations'] ?? json['data']) as List?;
    if (list == null) return const [];
    final out = <Reciter>[];
    for (final item in list) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! int) continue;
      final reciterName = item['reciter_name'] as String? ??
          (item['translated_name'] is Map
              ? (item['translated_name']['name'] as String?)
              : null);
      final style = item['style'] as String?;
      if (reciterName == null) continue;
      out.add(Reciter.quranCom(
        recitationId: id,
        displayName: reciterName,
        style: style,
        languageEn: 'ar',
      ));
    }
    return out;
  }

  List<Reciter> _parseCacheJson(String raw) {
    try {
      final list = (jsonDecode(raw) as Map?)?['reciters'];
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            if (Reciter.fromJson(item) case final r?) r,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<File> _resolveCacheFile() async {
    if (_cacheFileOverride != null) return _cacheFileOverride!();
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, cacheFileName));
  }
}
