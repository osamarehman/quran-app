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

/// 114 surah entries (id, Arabic name, English meaning, transliteration).
const List<SurahMeta> kSurahNames = <SurahMeta>[
  SurahMeta(id: 1, ar: 'الفاتحة', en: 'The Opening', transliteration: 'Al-Fatiha'),
  SurahMeta(id: 2, ar: 'البقرة', en: 'The Cow', transliteration: 'Al-Baqarah'),
  SurahMeta(id: 3, ar: 'آل عمران', en: 'The Family of Imran', transliteration: 'Aal-i-Imran'),
  SurahMeta(id: 4, ar: 'النساء', en: 'The Women', transliteration: 'An-Nisa'),
  SurahMeta(id: 5, ar: 'المائدة', en: 'The Table Spread', transliteration: 'Al-Maidah'),
  SurahMeta(id: 6, ar: 'الأنعام', en: 'The Cattle', transliteration: 'Al-Anam'),
  SurahMeta(id: 7, ar: 'الأعراف', en: 'The Heights', transliteration: 'Al-Araf'),
  SurahMeta(id: 8, ar: 'الأنفال', en: 'The Spoils of War', transliteration: 'Al-Anfal'),
  SurahMeta(id: 9, ar: 'التوبة', en: 'The Repentance', transliteration: 'At-Tawbah'),
  SurahMeta(id: 10, ar: 'يونس', en: 'Jonah', transliteration: 'Yunus'),
  SurahMeta(id: 11, ar: 'هود', en: 'Hud', transliteration: 'Hud'),
  SurahMeta(id: 12, ar: 'يوسف', en: 'Joseph', transliteration: 'Yusuf'),
  SurahMeta(id: 13, ar: 'الرعد', en: 'The Thunder', transliteration: 'Ar-Rad'),
  SurahMeta(id: 14, ar: 'إبراهيم', en: 'Abraham', transliteration: 'Ibrahim'),
  SurahMeta(id: 15, ar: 'الحجر', en: 'The Rocky Tract', transliteration: 'Al-Hijr'),
  SurahMeta(id: 16, ar: 'النحل', en: 'The Bee', transliteration: 'An-Nahl'),
  SurahMeta(id: 17, ar: 'الإسراء', en: 'The Night Journey', transliteration: 'Al-Isra'),
  SurahMeta(id: 18, ar: 'الكهف', en: 'The Cave', transliteration: 'Al-Kahf'),
  SurahMeta(id: 19, ar: 'مريم', en: 'Mary', transliteration: 'Maryam'),
  SurahMeta(id: 20, ar: 'طه', en: 'Ta-Ha', transliteration: 'Ta-Ha'),
  SurahMeta(id: 21, ar: 'الأنبياء', en: 'The Prophets', transliteration: 'Al-Anbiya'),
  SurahMeta(id: 22, ar: 'الحج', en: 'The Pilgrimage', transliteration: 'Al-Hajj'),
  SurahMeta(id: 23, ar: 'المؤمنون', en: 'The Believers', transliteration: 'Al-Muminun'),
  SurahMeta(id: 24, ar: 'النور', en: 'The Light', transliteration: 'An-Nur'),
  SurahMeta(id: 25, ar: 'الفرقان', en: 'The Criterion', transliteration: 'Al-Furqan'),
  SurahMeta(id: 26, ar: 'الشعراء', en: 'The Poets', transliteration: 'Ash-Shuara'),
  SurahMeta(id: 27, ar: 'النمل', en: 'The Ant', transliteration: 'An-Naml'),
  SurahMeta(id: 28, ar: 'القصص', en: 'The Stories', transliteration: 'Al-Qasas'),
  SurahMeta(id: 29, ar: 'العنكبوت', en: 'The Spider', transliteration: 'Al-Ankabut'),
  SurahMeta(id: 30, ar: 'الروم', en: 'The Romans', transliteration: 'Ar-Rum'),
  SurahMeta(id: 31, ar: 'لقمان', en: 'Luqman', transliteration: 'Luqman'),
  SurahMeta(id: 32, ar: 'السجدة', en: 'The Prostration', transliteration: 'As-Sajdah'),
  SurahMeta(id: 33, ar: 'الأحزاب', en: 'The Combined Forces', transliteration: 'Al-Ahzab'),
  SurahMeta(id: 34, ar: 'سبأ', en: 'Sheba', transliteration: 'Saba'),
  SurahMeta(id: 35, ar: 'فاطر', en: 'Originator', transliteration: 'Fatir'),
  SurahMeta(id: 36, ar: 'يس', en: 'Ya-Sin', transliteration: 'Ya-Sin'),
  SurahMeta(id: 37, ar: 'الصافات', en: 'Those Who Set The Ranks', transliteration: 'As-Saffat'),
  SurahMeta(id: 38, ar: 'ص', en: 'The Letter Saad', transliteration: 'Sad'),
  SurahMeta(id: 39, ar: 'الزمر', en: 'The Troops', transliteration: 'Az-Zumar'),
  SurahMeta(id: 40, ar: 'غافر', en: 'The Forgiver', transliteration: 'Ghafir'),
  SurahMeta(id: 41, ar: 'فصلت', en: 'Explained In Detail', transliteration: 'Fussilat'),
  SurahMeta(id: 42, ar: 'الشورى', en: 'The Consultation', transliteration: 'Ash-Shura'),
  SurahMeta(id: 43, ar: 'الزخرف', en: 'The Ornaments of Gold', transliteration: 'Az-Zukhruf'),
  SurahMeta(id: 44, ar: 'الدخان', en: 'The Smoke', transliteration: 'Ad-Dukhan'),
  SurahMeta(id: 45, ar: 'الجاثية', en: 'The Crouching', transliteration: 'Al-Jathiyah'),
  SurahMeta(id: 46, ar: 'الأحقاف', en: 'The Wind-Curved Sandhills', transliteration: 'Al-Ahqaf'),
  SurahMeta(id: 47, ar: 'محمد', en: 'Muhammad', transliteration: 'Muhammad'),
  SurahMeta(id: 48, ar: 'الفتح', en: 'The Victory', transliteration: 'Al-Fath'),
  SurahMeta(id: 49, ar: 'الحجرات', en: 'The Rooms', transliteration: 'Al-Hujurat'),
  SurahMeta(id: 50, ar: 'ق', en: 'The Letter Qaf', transliteration: 'Qaf'),
  SurahMeta(id: 51, ar: 'الذاريات', en: 'The Winnowing Winds', transliteration: 'Adh-Dhariyat'),
  SurahMeta(id: 52, ar: 'الطور', en: 'The Mount', transliteration: 'At-Tur'),
  SurahMeta(id: 53, ar: 'النجم', en: 'The Star', transliteration: 'An-Najm'),
  SurahMeta(id: 54, ar: 'القمر', en: 'The Moon', transliteration: 'Al-Qamar'),
  SurahMeta(id: 55, ar: 'الرحمن', en: 'The Beneficent', transliteration: 'Ar-Rahman'),
  SurahMeta(id: 56, ar: 'الواقعة', en: 'The Inevitable', transliteration: 'Al-Waqiah'),
  SurahMeta(id: 57, ar: 'الحديد', en: 'The Iron', transliteration: 'Al-Hadid'),
  SurahMeta(id: 58, ar: 'المجادلة', en: 'The Pleading Woman', transliteration: 'Al-Mujadilah'),
  SurahMeta(id: 59, ar: 'الحشر', en: 'The Exile', transliteration: 'Al-Hashr'),
  SurahMeta(id: 60, ar: 'الممتحنة', en: 'She That Is To Be Examined', transliteration: 'Al-Mumtahanah'),
  SurahMeta(id: 61, ar: 'الصف', en: 'The Ranks', transliteration: 'As-Saff'),
  SurahMeta(id: 62, ar: 'الجمعة', en: 'The Congregation', transliteration: 'Al-Jumuah'),
  SurahMeta(id: 63, ar: 'المنافقون', en: 'The Hypocrites', transliteration: 'Al-Munafiqun'),
  SurahMeta(id: 64, ar: 'التغابن', en: 'The Mutual Disillusion', transliteration: 'At-Taghabun'),
  SurahMeta(id: 65, ar: 'الطلاق', en: 'The Divorce', transliteration: 'At-Talaq'),
  SurahMeta(id: 66, ar: 'التحريم', en: 'The Prohibition', transliteration: 'At-Tahrim'),
  SurahMeta(id: 67, ar: 'الملك', en: 'The Sovereignty', transliteration: 'Al-Mulk'),
  SurahMeta(id: 68, ar: 'القلم', en: 'The Pen', transliteration: 'Al-Qalam'),
  SurahMeta(id: 69, ar: 'الحاقة', en: 'The Reality', transliteration: 'Al-Haqqah'),
  SurahMeta(id: 70, ar: 'المعارج', en: 'The Ascending Stairways', transliteration: 'Al-Maarij'),
  SurahMeta(id: 71, ar: 'نوح', en: 'Noah', transliteration: 'Nuh'),
  SurahMeta(id: 72, ar: 'الجن', en: 'The Jinn', transliteration: 'Al-Jinn'),
  SurahMeta(id: 73, ar: 'المزمل', en: 'The Enshrouded One', transliteration: 'Al-Muzzammil'),
  SurahMeta(id: 74, ar: 'المدثر', en: 'The Cloaked One', transliteration: 'Al-Muddaththir'),
  SurahMeta(id: 75, ar: 'القيامة', en: 'The Resurrection', transliteration: 'Al-Qiyamah'),
  SurahMeta(id: 76, ar: 'الإنسان', en: 'The Man', transliteration: 'Al-Insan'),
  SurahMeta(id: 77, ar: 'المرسلات', en: 'The Emissaries', transliteration: 'Al-Mursalat'),
  SurahMeta(id: 78, ar: 'النبأ', en: 'The Tidings', transliteration: 'An-Naba'),
  SurahMeta(id: 79, ar: 'النازعات', en: 'Those Who Drag Forth', transliteration: 'An-Naziat'),
  SurahMeta(id: 80, ar: 'عبس', en: 'He Frowned', transliteration: 'Abasa'),
  SurahMeta(id: 81, ar: 'التكوير', en: 'The Overthrowing', transliteration: 'At-Takwir'),
  SurahMeta(id: 82, ar: 'الإنفطار', en: 'The Cleaving', transliteration: 'Al-Infitar'),
  SurahMeta(id: 83, ar: 'المطففين', en: 'The Defrauding', transliteration: 'Al-Mutaffifin'),
  SurahMeta(id: 84, ar: 'الإنشقاق', en: 'The Splitting Open', transliteration: 'Al-Inshiqaq'),
  SurahMeta(id: 85, ar: 'البروج', en: 'The Mansions of the Stars', transliteration: 'Al-Buruj'),
  SurahMeta(id: 86, ar: 'الطارق', en: 'The Morning Star', transliteration: 'At-Tariq'),
  SurahMeta(id: 87, ar: 'الأعلى', en: 'The Most High', transliteration: 'Al-Ala'),
  SurahMeta(id: 88, ar: 'الغاشية', en: 'The Overwhelming', transliteration: 'Al-Ghashiyah'),
  SurahMeta(id: 89, ar: 'الفجر', en: 'The Dawn', transliteration: 'Al-Fajr'),
  SurahMeta(id: 90, ar: 'البلد', en: 'The City', transliteration: 'Al-Balad'),
  SurahMeta(id: 91, ar: 'الشمس', en: 'The Sun', transliteration: 'Ash-Shams'),
  SurahMeta(id: 92, ar: 'الليل', en: 'The Night', transliteration: 'Al-Layl'),
  SurahMeta(id: 93, ar: 'الضحى', en: 'The Morning Hours', transliteration: 'Ad-Duha'),
  SurahMeta(id: 94, ar: 'الشرح', en: 'The Relief', transliteration: 'Ash-Sharh'),
  SurahMeta(id: 95, ar: 'التين', en: 'The Fig', transliteration: 'At-Tin'),
  SurahMeta(id: 96, ar: 'العلق', en: 'The Clot', transliteration: 'Al-Alaq'),
  SurahMeta(id: 97, ar: 'القدر', en: 'The Power', transliteration: 'Al-Qadr'),
  SurahMeta(id: 98, ar: 'البينة', en: 'The Clear Proof', transliteration: 'Al-Bayyinah'),
  SurahMeta(id: 99, ar: 'الزلزلة', en: 'The Earthquake', transliteration: 'Az-Zalzalah'),
  SurahMeta(id: 100, ar: 'العاديات', en: 'The Courser', transliteration: 'Al-Adiyat'),
  SurahMeta(id: 101, ar: 'القارعة', en: 'The Calamity', transliteration: 'Al-Qariah'),
  SurahMeta(id: 102, ar: 'التكاثر', en: 'The Rivalry in World Increase', transliteration: 'At-Takathur'),
  SurahMeta(id: 103, ar: 'العصر', en: 'The Declining Day', transliteration: 'Al-Asr'),
  SurahMeta(id: 104, ar: 'الهمزة', en: 'The Traducer', transliteration: 'Al-Humazah'),
  SurahMeta(id: 105, ar: 'الفيل', en: 'The Elephant', transliteration: 'Al-Fil'),
  SurahMeta(id: 106, ar: 'قريش', en: 'Quraish', transliteration: 'Quraish'),
  SurahMeta(id: 107, ar: 'الماعون', en: 'The Small Kindnesses', transliteration: 'Al-Maun'),
  SurahMeta(id: 108, ar: 'الكوثر', en: 'The Abundance', transliteration: 'Al-Kawthar'),
  SurahMeta(id: 109, ar: 'الكافرون', en: 'The Disbelievers', transliteration: 'Al-Kafirun'),
  SurahMeta(id: 110, ar: 'النصر', en: 'The Divine Support', transliteration: 'An-Nasr'),
  SurahMeta(id: 111, ar: 'المسد', en: 'The Palm Fiber', transliteration: 'Al-Masad'),
  SurahMeta(id: 112, ar: 'الإخلاص', en: 'The Sincerity', transliteration: 'Al-Ikhlas'),
  SurahMeta(id: 113, ar: 'الفلق', en: 'The Daybreak', transliteration: 'Al-Falaq'),
  SurahMeta(id: 114, ar: 'الناس', en: 'Mankind', transliteration: 'An-Nas'),
];

/// 30 Arabic juz incipits (first words of each juz), in order juz 1..30.
const List<String> kJuzNamesAr = <String>[
  'الٓمٓ',           // 1
  'سَيَقُولُ',         // 2
  'تِلْكَ ٱلرُّسُلُ',     // 3
  'لَن تَنَالُوا',       // 4
  'وَٱلْمُحْصَنَاتُ',    // 5
  'لَا يُحِبُّ ٱللَّهُ',   // 6
  'وَإِذَا سَمِعُوا',    // 7
  'وَلَوْ أَنَّنَا',       // 8
  'قَالَ ٱلْمَلَأُ',      // 9
  'وَٱعْلَمُوٓا',       // 10
  'يَعْتَذِرُونَ',       // 11
  'وَمَا مِن دَآبَّةٍ',   // 12
  'وَمَآ أُبَرِّئُ',      // 13
  'رُبَمَا',           // 14
  'سُبْحَانَ ٱلَّذِيٓ',   // 15
  'قَالَ أَلَمْ',        // 16
  'ٱقْتَرَبَ',          // 17
  'قَدْ أَفْلَحَ',        // 18
  'وَقَالَ ٱلَّذِينَ',    // 19
  'أَمَّنْ خَلَقَ',       // 20
  'ٱتْلُ مَآ أُوحِيَ',   // 21
  'وَمَن يَقْنُتْ',     // 22
  'وَمَا لِيَ',         // 23
  'فَمَنْ أَظْلَمُ',     // 24
  'إِلَيْهِ يُرَدُّ',       // 25
  'حمٓ',             // 26
  'قَالَ فَمَا خَطْبُكُمْ', // 27
  'قَدْ سَمِعَ ٱللَّهُ',  // 28
  'تَبَارَكَ ٱلَّذِى',    // 29
  'عَمَّ',             // 30
];

/// 30 (surah, ayah) pairs marking the start of each juz, in order 1..30.
const List<(int, int)> _kJuzStarts = <(int, int)>[
  (1, 1),     // 1  - Al-Fatiha 1
  (2, 142),   // 2  - Al-Baqarah 142
  (2, 253),   // 3  - Al-Baqarah 253
  (3, 93),    // 4  - Aal-i-Imran 93
  (4, 24),    // 5  - An-Nisa 24
  (4, 148),   // 6  - An-Nisa 148
  (5, 82),    // 7  - Al-Maidah 82
  (6, 111),   // 8  - Al-Anam 111
  (7, 88),    // 9  - Al-Araf 88
  (8, 41),    // 10 - Al-Anfal 41
  (9, 93),    // 11 - At-Tawbah 93
  (11, 6),    // 12 - Hud 6
  (12, 53),   // 13 - Yusuf 53
  (15, 1),    // 14 - Al-Hijr 1
  (17, 1),    // 15 - Al-Isra 1
  (18, 75),   // 16 - Al-Kahf 75
  (21, 1),    // 17 - Al-Anbiya 1
  (23, 1),    // 18 - Al-Muminun 1
  (25, 21),   // 19 - Al-Furqan 21
  (27, 56),   // 20 - An-Naml 56
  (29, 46),   // 21 - Al-Ankabut 46
  (33, 31),   // 22 - Al-Ahzab 31
  (36, 28),   // 23 - Ya-Sin 28
  (39, 32),   // 24 - Az-Zumar 32
  (41, 47),   // 25 - Fussilat 47
  (46, 1),    // 26 - Al-Ahqaf 1
  (51, 31),   // 27 - Adh-Dhariyat 31
  (58, 1),    // 28 - Al-Mujadilah 1
  (67, 1),    // 29 - Al-Mulk 1
  (78, 1),    // 30 - An-Naba 1
];

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
