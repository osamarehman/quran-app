import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mushaf/audio/reciter_catalog.dart';

http.Response _utf8Response(String body, [int code = 200]) =>
    http.Response.bytes(utf8.encode(body), code,
        headers: {'content-type': 'application/json; charset=utf-8'});

const String _alquranBody = '''
{
  "code": 200,
  "status": "OK",
  "data": [
    {
      "identifier": "ar.alafasy",
      "language": "ar",
      "name": "مشاري راشد العفاسي",
      "englishName": "Alafasy",
      "format": "audio",
      "type": "versebyverse",
      "direction": null
    },
    {
      "identifier": "ar.husary",
      "language": "ar",
      "name": "محمود خليل الحصري",
      "englishName": "Husary",
      "format": "audio",
      "type": "versebyverse",
      "direction": null
    }
  ]
}
''';

const String _quranComBody = '''
{
  "recitations": [
    {
      "id": 7,
      "reciter_name": "Mishari Rashid al-`Afasy",
      "style": "Mujawwad",
      "translated_name": { "name": "Alafasy", "language_name": "english" }
    }
  ]
}
''';

void main() {
  // Use a temp dir for the cache file so tests don't touch real app docs.
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reciter_catalog_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('all() merges alquran.cloud + quran.com results', () async {
    final mock = MockClient((req) async {
      final u = req.url.toString();
      if (u.contains('api.alquran.cloud')) {
        return _utf8Response(_alquranBody);
      }
      if (u.contains('api.quran.com')) {
        return _utf8Response(_quranComBody);
      }
      return _utf8Response("not found", 404);
    });

    final catalog = ReciterCatalog();
    catalog.debugConfigureForTest(
      client: mock,
      cacheFile: () async => File('${tempDir.path}/cache.json'),
    );

    final list = await catalog.all();

    // 2 alquran.cloud entries × 1 bitrate (128) + 1 quran.com = 3.
    // Bitrate fallback at playback time covers editions that don't ship
    // 128kbps, so we collapse the catalog to one entry per edition.
    expect(list.length, 3);

    final ids = list.map((r) => r.id).toSet();
    expect(ids, contains('alquran:ar.alafasy:128'));
    expect(ids, contains('alquran:ar.husary:128'));
    expect(ids, contains('quran-com:7'));

    final alafasy =
        list.firstWhere((r) => r.id == 'alquran:ar.alafasy:128');
    expect(alafasy.displayName, 'Alafasy');
    expect(alafasy.authorAr, 'مشاري راشد العفاسي');
    expect(alafasy.urlBuilder(1).toString(),
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3');

    expect(catalog.status.fromFallback, isFalse);
    expect(catalog.status.lastError, isNull);
  });

  test('byId returns the matching reciter', () async {
    final mock = MockClient((req) async {
      if (req.url.toString().contains('api.alquran.cloud')) {
        return _utf8Response(_alquranBody);
      }
      return _utf8Response('{"recitations":[]}');
    });
    final catalog = ReciterCatalog();
    catalog.debugConfigureForTest(
      client: mock,
      cacheFile: () async => File('${tempDir.path}/cache.json'),
    );

    final r = await catalog.byId('alquran:ar.husary:128');
    expect(r, isNotNull);
    expect(r!.displayName, 'Husary');
    expect(r.bitrate, 128);
  });

  test('falls back to defaults on hard network failure', () async {
    final mock = MockClient((req) async {
      throw const SocketException('offline');
    });
    final catalog = ReciterCatalog();
    catalog.debugConfigureForTest(
      client: mock,
      cacheFile: () async => File('${tempDir.path}/cache.json'),
    );

    final list = await catalog.all();
    expect(list, isNotEmpty);
    expect(catalog.status.fromFallback, isTrue);
    expect(list.any((r) => r.id == kDefaultReciterId), isTrue);
  });

  test('reads cached list on second call without hitting network', () async {
    var callCount = 0;
    final mock = MockClient((req) async {
      callCount++;
      if (req.url.toString().contains('api.alquran.cloud')) {
        return _utf8Response(_alquranBody);
      }
      return _utf8Response('{"recitations":[]}');
    });
    final cacheFile = File('${tempDir.path}/cache.json');
    final catalog = ReciterCatalog();
    catalog.debugConfigureForTest(
      client: mock,
      cacheFile: () async => cacheFile,
    );

    await catalog.all();
    expect(callCount, greaterThan(0));
    final firstCount = callCount;

    // Reset in-memory cache (simulate app restart) and call again.
    catalog.debugConfigureForTest(
      client: mock,
      cacheFile: () async => cacheFile,
    );
    final list = await catalog.all();
    expect(list, isNotEmpty);
    expect(callCount, firstCount,
        reason: 'second call should use disk cache, no extra network hits');
  });
}
