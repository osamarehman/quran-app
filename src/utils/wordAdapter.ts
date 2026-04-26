import { getWordsForRange as getWordsForRangeFromDb } from '../db/database';

let wordCache: Map<number, string> | null = null;

/**
 * Load all words from the SQLite words database into an in-memory cache.
 * This is called once during app initialization.
 */
export async function loadWordsIntoCache(): Promise<void> {
  if (wordCache) return;

  const allWords = await getWordsForRangeFromDb(1, 83668);
  const cache = new Map<number, string>();
  for (const row of allWords) {
    cache.set(row.id, row.text);
  }
  wordCache = cache;
}

export function getWordText(wordId: number): string | null {
  if (!wordCache) return null;
  return wordCache.get(wordId) ?? null;
}

export function getWordsForRange(firstWordId: number, lastWordId: number): string[] {
  const result: string[] = [];
  if (!wordCache || !firstWordId || !lastWordId) return result;

  for (let id = firstWordId; id <= lastWordId; id++) {
    const text = wordCache.get(id);
    if (text !== undefined) result.push(text);
  }
  return result;
}

export function isWordsCacheReady(): boolean {
  return wordCache !== null;
}
