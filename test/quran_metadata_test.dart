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

  group('kSajdaAyat', () {
    test('has exactly 14 entries (standard IndoPak list)', () {
      expect(kSajdaAyat.length, 14);
    });

    test('isSajda returns true for known sajda', () {
      expect(isSajda(7, 206), isTrue);
      expect(isSajda(96, 19), isTrue);
    });

    test('isSajda returns false for non-sajda', () {
      expect(isSajda(2, 1), isFalse);
      expect(isSajda(1, 1), isFalse);
      // 22:77 is NOT in the standard IndoPak 14-list, even though Tanzil
      // surfaces it as a 15th recommended sajda.
      expect(isSajda(22, 77), isFalse);
    });
  });

  group('kHizbStarts', () {
    test('has exactly 60 entries', () {
      expect(kHizbStarts.length, 60);
    });

    test('hizb 1 starts at Al-Fatiha 1:1', () {
      expect(hizbStartIndex(1, 1), 0);
    });

    test('hizbStartIndex returns null for non-hizb-start ayahs', () {
      expect(hizbStartIndex(2, 1), isNull);
      expect(hizbStartIndex(1, 2), isNull);
    });
  });

  group('kRukuStarts', () {
    // The canonical academic count from Tanzil/alquran.cloud is 556. Some
    // popular sources cite 540 or 558; we ship the canonical Tanzil count.
    test('has exactly 556 entries (Tanzil canonical count)', () {
      expect(kRukuStarts.length, 556);
    });

    test('first ruku starts at Al-Fatiha 1:1', () {
      expect(rukuStartIndex(1, 1), 0);
    });

    test('second ruku starts at Al-Baqara 2:1', () {
      expect(rukuStartIndex(2, 1), 1);
    });

    test('rukuStartIndex returns null for non-ruku-start ayahs', () {
      expect(rukuStartIndex(2, 2), isNull);
    });
  });
}
