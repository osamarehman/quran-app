# Data Requirements for Quran Mushaf App

## What's Already Working

The React Native (Expo) app is fully scaffolded and compiles without TypeScript errors.

- **15-line mushaf**: Qudratullah Indopak, 610 pages, 15 lines/page
- **16-line mushaf**: Taj Company Indopak, 548 pages, 16 lines/page
- **Fonts**: DigitalKhattIndoPak.otf + indopak-nastaleeq.ttf
- **Navigation**: Horizontal swipe paging with last-read persistence
- **Mode toggle**: Switch between 15-line and 16-line layouts

## The Missing Piece: Word-Level Database

The layout databases (`taj-indopak-16-lines.db` and `qudratullah-indopak-15-lines.db`) store **page layouts** with word ID ranges (1-83,668), but they do **NOT** contain the actual Arabic text.

### Why Simple Text Doesn't Match

- `quran-simple.txt` produces **82,826** words when split by spaces
- The layout DBs reference **83,668** word IDs
- Difference: **842 words** — the layout uses a different word segmentation (likely morphological splitting of prefixes like wa-, fa-, bi-)

### What You Need to Provide

A SQLite database or JSON file containing a `words` table with this schema:

```sql
CREATE TABLE words (
  id INTEGER PRIMARY KEY,      -- 1 to 83668
  surah INTEGER,               -- surah number (1-114)
  ayah INTEGER,                -- ayah number
  word TEXT                    -- Arabic text of the word
);
```

### How to Get It

1. **QUL (Quranic Universal Library)**: Download the mushaf layout export from qul.tarteel.ai. If you have access to the auth-protected site, look for a SQLite export that includes the `mushaf_words` or `words` table. The QUL Rails app connects to a separate `quran_dev` PostgreSQL database that holds this data.

2. **Quran.com API**: We checked this — their word IDs do NOT match the layout DB IDs (different numbering system).

3. **Build your own**: If you can obtain a word-by-word segmentation that matches the Indopak 16-line / 15-line editions, we can script the conversion.

### Current Fallback

The app currently uses a **best-effort fallback** that splits `quran-simple.txt` by spaces and assigns sequential IDs. This means:
- Surah names and basmallah lines render correctly
- Ayah lines render with approximate text
- Word boundaries will be slightly off (page lines may overflow or underflow)

### Next Steps

Once you obtain the word database:

1. Place it in `assets/databases/words.db` (or similar)
2. Update `src/utils/wordAdapter.ts` to load it instead of the fallback
3. The app will render pixel-perfect mushaf pages immediately

## Running the App

```bash
cd quran-mushaf-app
npx expo start
```

Then scan the QR code with Expo Go (Android/iOS) or press `a` / `i` to run on emulator.
