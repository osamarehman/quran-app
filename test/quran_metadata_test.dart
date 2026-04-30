import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/data/quran_metadata.dart';

void main() {
  group('juzForAyah', () {
    test('juz 1 starts at Al-Fatiha 1:1', () {
      expect(juzForAyah(1, 1), 1);
    });
    test('juz 2 starts at Al-Baqarah 2:142', () {
      expect(juzForAyah(2, 142), 2);
    });
    test('juz 3 starts at Al-Baqarah 2:253', () {
      expect(juzForAyah(2, 253), 3);
    });
    test('juz 30 starts at An-Naba 78:1', () {
      expect(juzForAyah(78, 1), 30);
    });
    test('An-Nas 114:6 is in juz 30', () {
      expect(juzForAyah(114, 6), 30);
    });
    test('Al-Baqarah 2:141 is still in juz 1', () {
      expect(juzForAyah(2, 141), 1);
    });
    test('77:50 still in juz 29 (juz 30 starts at 78:1)', () {
      expect(juzForAyah(77, 50), 29);
    });
  });

  group('metadata cardinality', () {
    test('114 surah entries', () {
      expect(kSurahNames.length, 114);
    });
    test('30 juz Arabic incipits', () {
      expect(kJuzNamesAr.length, 30);
    });
    test('surah ids run 1..114 in order', () {
      for (var i = 0; i < kSurahNames.length; i++) {
        expect(kSurahNames[i].id, i + 1);
      }
    });
  });
}
