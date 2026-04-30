import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/audio/reciter_catalog.dart';

void main() {
  group('Reciter.alquranCloud urlBuilder', () {
    test('builds canonical CDN URL for ayah 1', () {
      final r = Reciter.alquranCloud(
        editionSlug: 'ar.alafasy',
        displayName: 'Mishary Alafasy',
        bitrate: 128,
      );
      expect(
        r.urlBuilder(1).toString(),
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3',
      );
    });

    test('respects bitrate', () {
      final r = Reciter.alquranCloud(
        editionSlug: 'ar.husary',
        displayName: 'Husary',
        bitrate: 64,
      );
      expect(
        r.urlBuilder(7).toString(),
        'https://cdn.islamic.network/quran/audio/64/ar.husary/7.mp3',
      );
    });

    test('id encodes provider + slug + bitrate', () {
      final a = Reciter.alquranCloud(
        editionSlug: 'ar.alafasy',
        displayName: 'X',
        bitrate: 128,
      );
      final b = Reciter.alquranCloud(
        editionSlug: 'ar.alafasy',
        displayName: 'X',
        bitrate: 64,
      );
      expect(a.id, 'alquran:ar.alafasy:128');
      expect(b.id, 'alquran:ar.alafasy:64');
      expect(a.id == b.id, isFalse);
    });

    test('default reciters include alafasy@128', () {
      final ids = defaultReciters().map((r) => r.id).toList();
      expect(ids, contains(kDefaultReciterId));
    });
  });

  group('Reciter.quranCom', () {
    test('flags requiresMetadataFetch and encodes recitation id', () {
      final r = Reciter.quranCom(
        recitationId: 7,
        displayName: 'Mishari',
      );
      expect(r.id, 'quran-com:7');
      expect(r.requiresMetadataFetch, isTrue);
      expect(r.providerRecitationId, '7');
      expect(r.provider, kProviderQuranCom);
    });
  });
}
