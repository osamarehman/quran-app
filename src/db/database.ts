import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system/legacy';
import { Asset } from 'expo-asset';
import { PageLine, MushafMode } from '../types/mushaf';
import { MUSHAF_CONFIG, JUZ_STARTS } from '../utils/constants';

let db15Line: SQLite.SQLiteDatabase | null = null;
let db16Line: SQLite.SQLiteDatabase | null = null;
let dbWords: SQLite.SQLiteDatabase | null = null;

const DB_ASSETS: Record<string, number> = {
  [MUSHAF_CONFIG['15-line'].dbName]: require('../../assets/databases/qudratullah-indopak-15-lines.db'),
  [MUSHAF_CONFIG['16-line'].dbName]: require('../../assets/databases/taj-indopak-16-lines.db'),
  'words.db': require('../../assets/databases/words.db'),
};

async function openDatabaseIfNeeded(dbFileName: string): Promise<SQLite.SQLiteDatabase> {
  console.log('[DB] openDatabaseIfNeeded:', dbFileName);
  const sqliteDir = `${FileSystem.documentDirectory}SQLite`;
  const dbPath = `${sqliteDir}/${dbFileName}`;

  const dirInfo = await FileSystem.getInfoAsync(sqliteDir);
  if (!dirInfo.exists) {
    await FileSystem.makeDirectoryAsync(sqliteDir, { intermediates: true });
  }

  const fileInfo = await FileSystem.getInfoAsync(dbPath);
  console.log('[DB] fileExists:', dbFileName, fileInfo.exists);
  if (!fileInfo.exists) {
    console.log('[DB] copying asset:', dbFileName);
    const assetModule = DB_ASSETS[dbFileName];
    if (!assetModule) {
      throw new Error(`Database asset not found: ${dbFileName}`);
    }
    const asset = Asset.fromModule(assetModule);
    await asset.downloadAsync();
    console.log('[DB] downloaded:', dbFileName);
    if (!asset.localUri) {
      throw new Error(`Failed to download asset: ${dbFileName}`);
    }
    await FileSystem.copyAsync({ from: asset.localUri, to: dbPath });
    console.log('[DB] copied:', dbFileName);
  }

  console.log('[DB] opening:', dbFileName);
  const result = await SQLite.openDatabaseAsync(dbFileName);
  console.log('[DB] opened:', dbFileName);
  return result;
}

export async function initDatabases(): Promise<void> {
  if (!db15Line) {
    db15Line = await openDatabaseIfNeeded(MUSHAF_CONFIG['15-line'].dbName);
  }
  if (!db16Line) {
    db16Line = await openDatabaseIfNeeded(MUSHAF_CONFIG['16-line'].dbName);
  }
  if (!dbWords) {
    dbWords = await openDatabaseIfNeeded('words.db');
  }
}

function getDb(mode: MushafMode): SQLite.SQLiteDatabase {
  if (mode === '15-line') {
    if (!db15Line) throw new Error('15-line database not initialized');
    return db15Line;
  }
  if (!db16Line) throw new Error('16-line database not initialized');
  return db16Line;
}

export async function getPageLines(
  mode: MushafMode,
  pageNumber: number
): Promise<PageLine[]> {
  return getDb(mode).getAllAsync<PageLine>(
    'SELECT * FROM pages WHERE page_number = ? ORDER BY line_number',
    [pageNumber]
  );
}

export async function getLinesForWordRange(
  mode: MushafMode,
  firstWordId: number,
  lastWordId: number
): Promise<PageLine[]> {
  return getDb(mode).getAllAsync<PageLine>(
    'SELECT * FROM pages WHERE first_word_id >= ? AND last_word_id <= ? ORDER BY page_number, line_number',
    [firstWordId, lastWordId]
  );
}

export async function getPageForSurah(mode: MushafMode, surahNumber: number): Promise<number | null> {
  const db = getDb(mode);
  const row = await db.getFirstAsync<{ page_number: number }>(
    'SELECT MIN(page_number) as page_number FROM pages WHERE surah_number = ?',
    [surahNumber]
  );
  return row?.page_number ?? null;
}

type WordRow = { id: number; text: string; ayah: number; surah: number };

export async function getWordsForRange(
  firstWordId: number,
  lastWordId: number
): Promise<WordRow[]> {
  if (!dbWords) throw new Error('Words database not initialized');
  return dbWords.getAllAsync<WordRow>(
    'SELECT id, text, ayah, surah FROM words WHERE id >= ? AND id <= ? ORDER BY id',
    [firstWordId, lastWordId]
  );
}

// Returns the smallest word id for the given surah/ayah from the words DB.
async function getFirstWordIdForAyah(surah: number, ayah: number): Promise<number | null> {
  if (!dbWords) throw new Error('Words database not initialized');
  const row = await dbWords.getFirstAsync<{ id: number }>(
    'SELECT MIN(id) as id FROM words WHERE surah = ? AND ayah = ?',
    [surah, ayah]
  );
  return row?.id ?? null;
}

// Returns the page number in the mushaf that contains the given word id.
async function getPageForWordId(mode: MushafMode, wordId: number): Promise<number | null> {
  const db = getDb(mode);
  const row = await db.getFirstAsync<{ page_number: number }>(
    'SELECT page_number FROM pages WHERE first_word_id <= ? AND last_word_id >= ? LIMIT 1',
    [wordId, wordId]
  );
  return row?.page_number ?? null;
}

export async function getPageForJuz(mode: MushafMode, juzNumber: number): Promise<number | null> {
  const [surah, ayah] = JUZ_STARTS[juzNumber - 1];
  try {
    const wordId = await getFirstWordIdForAyah(surah, ayah);
    if (wordId != null) {
      const page = await getPageForWordId(mode, wordId);
      if (page != null) return page;
    }
  } catch {
    // fall through to surah-start fallback
  }
  // fallback: use first page of the starting surah
  return getPageForSurah(mode, surah);
}

export async function getSurahNumberForPage(mode: MushafMode, page: number): Promise<number> {
  const db = getDb(mode);

  // Step 1: prefer surah_name line (a new surah starts on this page)
  const surahLine = await db.getFirstAsync<{ surah_number: number }>(
    `SELECT surah_number FROM pages WHERE page_number = ? AND line_type = 'surah_name' AND surah_number IS NOT NULL AND surah_number > 0 ORDER BY line_number LIMIT 1`,
    [page]
  );
  if (surahLine?.surah_number) return surahLine.surah_number;

  // Step 2: fall back to deriving the surah from the first word on this page
  const ayahLine = await db.getFirstAsync<{ first_word_id: number }>(
    `SELECT first_word_id FROM pages WHERE page_number = ? AND line_type = 'ayah' AND first_word_id IS NOT NULL ORDER BY line_number LIMIT 1`,
    [page]
  );
  if (ayahLine?.first_word_id && dbWords) {
    const wordRow = await dbWords.getFirstAsync<{ surah: number }>(
      'SELECT surah FROM words WHERE id = ? LIMIT 1',
      [ayahLine.first_word_id]
    );
    if (wordRow?.surah) return wordRow.surah;
  }

  return 1;
}

export async function getTotalPages(mode: MushafMode): Promise<number> {
  const db = getDb(mode);
  const row = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(DISTINCT page_number) as count FROM pages'
  );
  return row?.count ?? MUSHAF_CONFIG[mode].pages;
}
