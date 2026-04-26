# Google Play Store — Submission Guide

## Do You Need a New Build?

**Yes.** All recent changes (hizb position corrections, juz name fix, bug fixes, sidebar markers) are code changes that only take effect in a freshly compiled binary.

### Build command

```bash
eas build --profile production --platform android
```

This produces an `.aab` (Android App Bundle) that you upload to Play Console. `autoIncrement: true` in `eas.json` bumps the `versionCode` automatically each run.

### Submit after build

```bash
eas submit --platform android --latest
```

Or upload the `.aab` manually in Play Console → Production → Releases → Create new release.

---

## Graphic Assets

All assets must be PNG unless noted. No alpha channel on feature graphic or screenshots.

| Asset | Size | Status | Notes |
|-------|------|--------|-------|
| Hi-res icon | 512×512 px | **Needs export** | Resize `assets/icon.png` (1024×1024) to 512×512 |
| Feature graphic | 1024×500 px | **Must create** | Shown on store listing page; no text near edges |
| Phone screenshots | 1080×1920 px (min 2, max 8) | **Must take** | Portrait; take from device/emulator |
| 7" tablet screenshots | 1200×1920 px (optional) | — | |
| 10" tablet screenshots | 1920×1200 px (optional) | — | |
| Promo video | YouTube URL (optional) | — | 30–120 seconds |

### Export icon at 512×512

```bash
# Using ImageMagick (if installed):
magick assets/icon.png -resize 512x512 store-assets/icon-512.png

# Using ffmpeg:
ffmpeg -i assets/icon.png -vf scale=512:512 store-assets/icon-512.png
```

### Feature graphic tips

- 1024×500 px PNG, no alpha
- Keep important content in the center 820×360 area (edges may be cropped on some devices)
- Suggested: dark green/teal background, Arabic calligraphy, app name in English and Arabic

---

## Store Listing — Text Fields

### App name
> **Quran Mushaf — IndoPak**

Max 30 characters. Current: 26 ✓

---

### Short description (max 80 characters)
> Full IndoPak mushaf with 15 & 16 line modes, ruku/hizb markers, and audio recitation.

---

### Full description (max 4000 characters)

```
Quran Mushaf — IndoPak is a faithful digital reproduction of the IndoPak mushaf style, designed for readers familiar with the traditional Qudratullah (15-line) and Taj (16-line) prints.

FEATURES

• Two mushaf modes — switch between 15-line (Qudratullah) and 16-line (Taj) IndoPak layouts at any time
• Authentic fonts — DigitalKhatt IndoPak and IndoPak Nastaleeq typefaces
• Sidebar markers — ruku (ع), juz-ruku number, hizb quarter (ربع / نصف / ثلث), and sajda (سجدة) indicators on every page
• Correct juz labels — opening-word juz names derived directly from the page content, always accurate
• Waqf signs — traditional stop marks rendered faithfully in the correct font
• Pinch-to-zoom — zoom in for closer reading, tap to snap back
• Bookmarks — save your place and navigate your bookmark list
• Jump navigator — go to any surah or juz instantly
• Audio recitation — play any ayah with your chosen reciter
• Dark mode — comfortable reading in low light
• Offline — the complete Quran database is bundled; no internet required after installation

LAYOUT

Each page mirrors the printed mushaf: surah name header, page number, and juz label in the meta strip; ruku and hizb markers in the left sidebar; basmallah integrated into the surah name row.

AUDIO

Tap any ayah to hear its recitation. Multiple reciters available in Settings.

---

Quran text © respective database owners. App developed for personal Quran reading and study.
```

---

## Categorization

| Field | Value |
|-------|-------|
| Category | Books & Reference |
| Tags | quran, islam, quran recitation, mushaf, islamic |
| Content rating | Everyone (complete questionnaire — no violence, no ads, no user data) |

---

## Content Rating Questionnaire

Answer these in Play Console → App content → Ratings:

| Question | Answer |
|----------|--------|
| Does the app contain violence? | No |
| Does the app contain sexual content? | No |
| Does the app contain profanity? | No |
| Does the app contain controlled substances? | No |
| Does the app simulate gambling? | No |
| Is the app a news app? | No |
| Does it contain user-generated content? | No |
| Does the app target children under 13? | No (set to Everyone) |

Expected rating: **Everyone (E)**

---

## Data Safety Form

Answer in Play Console → App content → Data safety:

| Question | Answer |
|----------|--------|
| Does the app collect or share user data? | No |
| Does the app use location data? | No |
| Does the app use camera or microphone? | No |
| Does the app have account creation? | No |
| Does the app have ads? | No |

All data (bookmarks, last-read page, settings) is stored locally on-device via AsyncStorage. Nothing is transmitted.

---

## Contact Details

| Field | Value |
|-------|-------|
| Developer name | Usama Rehman |
| Email | osamarehmanmughal@gmail.com |
| Website | (optional — add if you have one) |

---

## Privacy Policy

A privacy policy URL is **required** even for apps that collect no data.

Suggested minimal policy content:
> This app does not collect, transmit, or share any personal data. All user preferences (bookmarks, last-read page, theme) are stored locally on your device and never leave it.

Host it on GitHub Pages, a Google Doc (published), or any public URL, then paste the URL into Play Console → App content → Privacy policy.

---

## App Details (app.json / Play Console)

| Field | Value |
|-------|-------|
| Package name | `com.usamar.quranmushafapp` |
| Version name | `1.0.0` |
| Version code | Auto-incremented by EAS on each production build |
| Min SDK | Android 6.0 (API 23) — set by Expo default |
| Target SDK | Android 14 (API 34) — set by Expo default |
| Permissions | `INTERNET` (audio streaming), `READ_EXTERNAL_STORAGE` (none needed — DB is bundled) |

---

## Pre-submission Checklist

- [ ] Production AAB built via `eas build --profile production --platform android`
- [ ] 512×512 icon exported
- [ ] Feature graphic created (1024×500)
- [ ] At least 2 phone screenshots taken
- [ ] Privacy policy URL live and pasted into Play Console
- [ ] Content rating questionnaire completed
- [ ] Data safety form filled
- [ ] Store listing text (name, short desc, full desc) entered
- [ ] Category set to Books & Reference
- [ ] Contact email entered
- [ ] AAB uploaded to a release track (Internal → Closed testing → Production)
