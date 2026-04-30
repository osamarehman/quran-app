import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mushaf/audio/audio_service.dart';
import 'package:mushaf/audio/reciter_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AudioService._resolveUrl', () {
    test('alquran.cloud reciter builds CDN URL without metadata fetch', () async {
      AudioService().debugConfigureForTest(
        client: MockClient((req) async => http.Response('', 500)),
      );
      final r = Reciter.alquranCloud(
        editionSlug: 'ar.alafasy',
        displayName: 'Mishary Alafasy',
        bitrate: 128,
      );
      final url = await AudioService().resolveUrlForTest(r, 1, 1, 1);
      expect(url, 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3');
    });

    test('Quran.com reciter hits /by_ayah_key/{surah}:{ayah}', () async {
      Uri? captured;
      AudioService().debugConfigureForTest(
        client: MockClient((req) async {
          captured = req.url;
          return http.Response(
            jsonEncode({
              'audio_files': [
                {'url': 'AbdulBaset/Mujawwad/001001.mp3'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final r = Reciter.quranCom(
        recitationId: 7,
        displayName: 'Mishari',
      );
      final url = await AudioService().resolveUrlForTest(r, 1, 2, 142);
      expect(captured?.path, contains('/by_ayah_key/2:142'));
      expect(url, 'https://verses.quran.com/AbdulBaset/Mujawwad/001001.mp3');
    });

    test('Quran.com cache hits skip the network on second call', () async {
      var hits = 0;
      AudioService().debugConfigureForTest(
        client: MockClient((req) async {
          hits++;
          return http.Response(
            jsonEncode({
              'audio_files': [
                {'url': 'X/001001.mp3'},
              ],
            }),
            200,
          );
        }),
      );
      final r = Reciter.quranCom(recitationId: 7, displayName: 'X');
      await AudioService().resolveUrlForTest(r, 1, 1, 1);
      await AudioService().resolveUrlForTest(r, 1, 1, 1);
      expect(hits, 1);
    });

    test('500 response surfaces lastError and returns null', () async {
      AudioService().debugConfigureForTest(
        client: MockClient((req) async => http.Response('boom', 500)),
      );
      final r = Reciter.quranCom(recitationId: 7, displayName: 'X');
      AudioService().lastError.value = null;
      final url = await AudioService().resolveUrlForTest(r, 1, 1, 1);
      expect(url, isNull);
      expect(AudioService().lastError.value, contains('500'));
    });
  });
}
