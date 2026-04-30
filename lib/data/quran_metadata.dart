/// Hardcoded const Quran metadata: surah names, juz incipits and starts,
/// sajda positions, hizb starts, ruku starts.
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

/// 14 (surah, ayah) sajda positions. Standard Hanafi/IndoPak list — does
/// not include the second sajda of Surah Al-Hajj (22:77), which Tanzil and
/// alquran.cloud list as a 15th "recommended" sajda. Source: hand-curated
/// to match the standard 14-sajda IndoPak mushaf marking.
const List<(int, int)> kSajdaAyat = <(int, int)>[
  (7, 206), (13, 15), (16, 50), (17, 109), (19, 58), (22, 18),
  (25, 60), (27, 26), (32, 15), (38, 24), (41, 38), (53, 62),
  (84, 21), (96, 19),
];

/// 60 (surah, ayah) hizb-start positions (= every 4th hizb-quarter from
/// Tanzil's quarters list, picking indices 1, 5, 9, ... 237). Hizb 1 begins
/// at Al-Fatiha 1:1; each juz contains exactly two hizbs.
/// Source: https://tanzil.net/res/text/metadata/quran-data.xml
const List<(int, int)> kHizbStarts = <(int, int)>[
  (1, 1), (2, 75), (2, 142), (2, 203), (2, 253), (3, 15),
  (3, 93), (3, 171), (4, 24), (4, 88), (4, 148), (5, 27),
  (5, 82), (6, 36), (6, 111), (7, 1), (7, 88), (7, 171),
  (8, 41), (9, 34), (9, 93), (10, 26), (11, 6), (11, 84),
  (12, 53), (13, 19), (15, 1), (16, 51), (17, 1), (17, 99),
  (18, 75), (20, 1), (21, 1), (22, 1), (23, 1), (24, 21),
  (25, 21), (26, 111), (27, 56), (28, 51), (29, 46), (31, 22),
  (33, 31), (34, 24), (36, 28), (37, 145), (39, 32), (40, 41),
  (41, 47), (43, 24), (46, 1), (48, 18), (51, 31), (55, 1),
  (58, 1), (62, 1), (67, 1), (72, 1), (78, 1), (87, 1),
];

/// 556 (surah, ayah) ruku-start positions, taken from Tanzil's ruku table
/// (which matches the alquran.cloud /meta endpoint exactly). Note: some
/// popular sources cite 540 or 558; the canonical academic count from
/// Tanzil is 556 and that's what we ship.
/// Source: https://tanzil.net/res/text/metadata/quran-data.xml
const List<(int, int)> kRukuStarts = <(int, int)>[
  (1, 1), (2, 1), (2, 8), (2, 21), (2, 30), (2, 40),
  (2, 47), (2, 60), (2, 62), (2, 72), (2, 83), (2, 87),
  (2, 97), (2, 104), (2, 113), (2, 122), (2, 130), (2, 142),
  (2, 148), (2, 153), (2, 164), (2, 168), (2, 177), (2, 183),
  (2, 189), (2, 197), (2, 211), (2, 217), (2, 222), (2, 229),
  (2, 232), (2, 236), (2, 243), (2, 249), (2, 254), (2, 258),
  (2, 261), (2, 267), (2, 274), (2, 282), (2, 284), (3, 1),
  (3, 10), (3, 21), (3, 31), (3, 42), (3, 55), (3, 64),
  (3, 72), (3, 81), (3, 92), (3, 102), (3, 110), (3, 121),
  (3, 130), (3, 144), (3, 149), (3, 156), (3, 172), (3, 181),
  (3, 190), (4, 1), (4, 11), (4, 15), (4, 23), (4, 26),
  (4, 34), (4, 43), (4, 51), (4, 60), (4, 71), (4, 77),
  (4, 88), (4, 92), (4, 97), (4, 101), (4, 105), (4, 113),
  (4, 116), (4, 127), (4, 135), (4, 142), (4, 153), (4, 163),
  (4, 172), (5, 1), (5, 6), (5, 12), (5, 20), (5, 27),
  (5, 35), (5, 44), (5, 51), (5, 57), (5, 67), (5, 78),
  (5, 87), (5, 94), (5, 101), (5, 109), (5, 116), (6, 1),
  (6, 11), (6, 21), (6, 31), (6, 42), (6, 51), (6, 56),
  (6, 61), (6, 71), (6, 83), (6, 91), (6, 95), (6, 101),
  (6, 111), (6, 122), (6, 130), (6, 141), (6, 145), (6, 151),
  (6, 155), (7, 1), (7, 11), (7, 26), (7, 32), (7, 40),
  (7, 48), (7, 54), (7, 59), (7, 65), (7, 73), (7, 85),
  (7, 94), (7, 100), (7, 109), (7, 127), (7, 130), (7, 142),
  (7, 148), (7, 152), (7, 158), (7, 163), (7, 172), (7, 182),
  (7, 189), (8, 1), (8, 11), (8, 20), (8, 29), (8, 38),
  (8, 45), (8, 49), (8, 59), (8, 65), (8, 70), (9, 1),
  (9, 7), (9, 17), (9, 25), (9, 30), (9, 38), (9, 43),
  (9, 60), (9, 67), (9, 73), (9, 81), (9, 90), (9, 100),
  (9, 111), (9, 119), (9, 123), (10, 1), (10, 11), (10, 21),
  (10, 31), (10, 41), (10, 54), (10, 61), (10, 71), (10, 83),
  (10, 93), (10, 104), (11, 1), (11, 9), (11, 25), (11, 36),
  (11, 50), (11, 61), (11, 69), (11, 84), (11, 96), (11, 110),
  (12, 1), (12, 7), (12, 21), (12, 30), (12, 36), (12, 43),
  (12, 50), (12, 58), (12, 69), (12, 80), (12, 94), (12, 105),
  (13, 1), (13, 8), (13, 19), (13, 27), (13, 32), (13, 38),
  (14, 1), (14, 7), (14, 13), (14, 22), (14, 28), (14, 35),
  (14, 42), (15, 1), (15, 16), (15, 26), (15, 45), (15, 61),
  (15, 80), (16, 1), (16, 10), (16, 22), (16, 26), (16, 35),
  (16, 41), (16, 51), (16, 61), (16, 66), (16, 71), (16, 77),
  (16, 84), (16, 90), (16, 101), (16, 111), (16, 120), (17, 1),
  (17, 11), (17, 23), (17, 31), (17, 41), (17, 53), (17, 61),
  (17, 71), (17, 78), (17, 85), (17, 94), (17, 101), (18, 1),
  (18, 13), (18, 18), (18, 23), (18, 32), (18, 45), (18, 50),
  (18, 54), (18, 60), (18, 71), (18, 83), (18, 102), (19, 1),
  (19, 16), (19, 41), (19, 51), (19, 66), (19, 83), (20, 1),
  (20, 25), (20, 55), (20, 77), (20, 90), (20, 105), (20, 116),
  (20, 129), (21, 1), (21, 11), (21, 30), (21, 42), (21, 51),
  (21, 76), (21, 94), (22, 1), (22, 11), (22, 23), (22, 26),
  (22, 34), (22, 39), (22, 49), (22, 58), (22, 65), (22, 73),
  (23, 1), (23, 23), (23, 33), (23, 51), (23, 78), (23, 93),
  (24, 1), (24, 11), (24, 21), (24, 27), (24, 35), (24, 41),
  (24, 51), (24, 58), (24, 62), (25, 1), (25, 10), (25, 21),
  (25, 35), (25, 45), (25, 61), (26, 1), (26, 10), (26, 34),
  (26, 53), (26, 70), (26, 105), (26, 123), (26, 141), (26, 160),
  (26, 176), (26, 192), (27, 1), (27, 15), (27, 32), (27, 45),
  (27, 59), (27, 67), (27, 83), (28, 1), (28, 14), (28, 22),
  (28, 29), (28, 43), (28, 51), (28, 61), (28, 76), (29, 1),
  (29, 14), (29, 23), (29, 31), (29, 45), (29, 52), (29, 64),
  (30, 1), (30, 11), (30, 20), (30, 28), (30, 41), (30, 54),
  (31, 1), (31, 12), (31, 20), (32, 1), (32, 12), (32, 23),
  (33, 1), (33, 9), (33, 21), (33, 28), (33, 35), (33, 41),
  (33, 53), (33, 59), (33, 69), (34, 1), (34, 10), (34, 22),
  (34, 31), (34, 37), (34, 46), (35, 1), (35, 8), (35, 15),
  (35, 27), (35, 38), (36, 1), (36, 13), (36, 33), (36, 51),
  (36, 68), (37, 1), (37, 22), (37, 75), (37, 114), (37, 139),
  (38, 1), (38, 15), (38, 27), (38, 41), (38, 65), (39, 1),
  (39, 10), (39, 22), (39, 32), (39, 42), (39, 53), (39, 64),
  (39, 71), (40, 1), (40, 10), (40, 21), (40, 28), (40, 38),
  (40, 51), (40, 61), (40, 69), (40, 79), (41, 1), (41, 9),
  (41, 19), (41, 26), (41, 33), (41, 45), (42, 1), (42, 10),
  (42, 20), (42, 30), (42, 44), (43, 1), (43, 16), (43, 26),
  (43, 36), (43, 46), (43, 57), (43, 68), (44, 1), (44, 30),
  (44, 43), (45, 1), (45, 12), (45, 22), (45, 27), (46, 1),
  (46, 11), (46, 21), (46, 27), (47, 1), (47, 12), (47, 20),
  (47, 29), (48, 1), (48, 11), (48, 18), (48, 27), (49, 1),
  (49, 11), (50, 1), (50, 16), (50, 30), (51, 1), (51, 24),
  (51, 47), (52, 1), (52, 29), (53, 1), (53, 26), (53, 33),
  (54, 1), (54, 23), (54, 41), (55, 1), (55, 26), (55, 46),
  (56, 1), (56, 39), (56, 75), (57, 1), (57, 11), (57, 20),
  (57, 26), (58, 1), (58, 7), (58, 14), (59, 1), (59, 11),
  (59, 18), (60, 1), (60, 7), (61, 1), (61, 10), (62, 1),
  (62, 9), (63, 1), (63, 9), (64, 1), (64, 11), (65, 1),
  (65, 8), (66, 1), (66, 8), (67, 1), (67, 15), (68, 1),
  (68, 34), (69, 1), (69, 38), (70, 1), (70, 36), (71, 1),
  (71, 21), (72, 1), (72, 20), (73, 1), (73, 20), (74, 1),
  (74, 32), (75, 1), (75, 31), (76, 1), (76, 23), (77, 1),
  (77, 41), (78, 1), (78, 31), (79, 1), (79, 27), (80, 1),
  (81, 1), (82, 1), (83, 1), (84, 1), (85, 1), (86, 1),
  (87, 1), (88, 1), (89, 1), (90, 1), (91, 1), (92, 1),
  (93, 1), (94, 1), (95, 1), (96, 1), (97, 1), (98, 1),
  (99, 1), (100, 1), (101, 1), (102, 1), (103, 1), (104, 1),
  (105, 1), (106, 1), (107, 1), (108, 1), (109, 1), (110, 1),
  (111, 1), (112, 1), (113, 1), (114, 1),
];

int juzForAyah(int surah, int ayah) {
  var j = 1;
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

bool isSajda(int surah, int ayah) => kSajdaAyat.contains((surah, ayah));

int? hizbStartIndex(int surah, int ayah) {
  final i = kHizbStarts.indexOf((surah, ayah));
  return i == -1 ? null : i;
}

int? rukuStartIndex(int surah, int ayah) {
  final i = kRukuStarts.indexOf((surah, ayah));
  return i == -1 ? null : i;
}
