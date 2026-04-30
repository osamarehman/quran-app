/// Hardcoded const Quran metadata. Stubs in this file are populated by
/// the v0.2 Stage 1 implementer agents (see plan):
///
/// - Agent A populates [kSurahNames], [kJuzNamesAr], [_kJuzStarts],
///   and the [juzForAyah] / [juzNumberForPagePrimaryAyah] helpers.
/// - Agent D populates [kSajdaAyat], [kHizbStarts], [kRukuStarts] and
///   the [isSajda] / [hizbStartIndex] / [rukuStartIndex] helpers.
///
/// Until then, [juzForAyah] returns 1, the lookups return null/false,
/// and the lists are empty so the rest of the app compiles cleanly.
library;

class SurahMeta {
  final int id;
  final String ar;
  final String en;
  final String transliteration;
  const SurahMeta({
    required this.id,
    required this.ar,
    required this.en,
    required this.transliteration,
  });
}

/// 114 entries by Agent A.
const List<SurahMeta> kSurahNames = <SurahMeta>[];

/// 30 Arabic juz incipits ("الٓمٓ", "سَيَقُولُ", ...) by Agent A.
const List<String> kJuzNamesAr = <String>[];

/// 30 (surah, ayah) pairs marking the start of each juz, by Agent A.
const List<(int, int)> _kJuzStarts = <(int, int)>[];

/// 14 (surah, ayah) sajda positions by Agent D.
const List<(int, int)> kSajdaAyat = <(int, int)>[];

/// 60 (surah, ayah) hizb-start positions by Agent D.
const List<(int, int)> kHizbStarts = <(int, int)>[];

/// 558 (surah, ayah) ruku-start positions by Agent D.
const List<(int, int)> kRukuStarts = <(int, int)>[];

int juzForAyah(int surah, int ayah) {
  if (_kJuzStarts.isEmpty) return 1;
  // Linear scan is fine for 30 entries; agent may swap to binary search.
  int j = 1;
  for (var i = 0; i < _kJuzStarts.length; i++) {
    final (s, a) = _kJuzStarts[i];
    if (surah > s || (surah == s && ayah >= a)) {
      j = i + 1;
    } else {
      break;
    }
  }
  return j;
}

bool isSajda(int surah, int ayah) =>
    kSajdaAyat.contains((surah, ayah));

int? hizbStartIndex(int surah, int ayah) {
  for (var i = 0; i < kHizbStarts.length; i++) {
    if (kHizbStarts[i] == (surah, ayah)) return i;
  }
  return null;
}

int? rukuStartIndex(int surah, int ayah) {
  for (var i = 0; i < kRukuStarts.length; i++) {
    if (kRukuStarts[i] == (surah, ayah)) return i;
  }
  return null;
}
