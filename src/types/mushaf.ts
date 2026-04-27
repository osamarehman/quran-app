export type LineType = 'surah_name' | 'basmallah' | 'ayah';
export type MushafMode = '15-line' | '16-line';
export type ThemeMode = 'light' | 'dark';

export interface PageLine {
  page_number: number;
  line_number: number;
  line_type: LineType;
  is_centered: 0 | 1;
  first_word_id: number | null;
  last_word_id: number | null;
  surah_number: number | null;
  wordText?: string;
  ayahNumber?: number;
  rukuNumber?: number;
  juzRukuNumber?: number;
  hizbMarker?: string;
  sajdaMarker?: boolean;
  endAyahNumber?: number;
  endSurahNumber?: number;
  // Per-ayah word groups so a line that spans multiple ayahs can render
  // one Pressable per ayah (correct hit target + correct audio).
  ayahSegments?: Array<{ surah: number; ayah: number; text: string }>;
  // True when this line is the first line of a new Juz (used to render the
  // line with inverted styling so the boundary stands out).
  isJuzFirstLine?: boolean;
}

export interface WordRecord {
  id: number;
  surah: number;
  ayah: number;
  word: string;
}

export interface SurahInfo {
  number: number;
  name: string;
  englishName: string;
  verses: number;
  page: number;
}
