import { useEffect, useState } from 'react';
import { getPageLines, getWordsForRange } from '../db/database';
import { PageLine, MushafMode } from '../types/mushaf';
import { RUKU_ENDS, JUZ_QUARTER_BOUNDARIES, JUZ_RUKU, SAJDA_AYAHS, JUZ_STARTS } from '../utils/constants';

export function usePageData(mode: MushafMode, pageNumber: number) {
  const [lines, setLines] = useState<PageLine[]>([]);
  const [pageSurahNumber, setPageSurahNumber] = useState<number>(0);
  const [pageJuzNumber, setPageJuzNumber] = useState<number>(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    async function fetch() {
      try {
        const rawLines = await getPageLines(mode, pageNumber);

        const ayahLines = rawLines.filter(
          (l) => l.line_type === 'ayah' && l.first_word_id != null && l.last_word_id != null
        );

        // minId must be hoisted out of the `if` so wordMap.get(minId) below works for firstWordEntry
        let minId = Infinity;
        const wordMap = new Map<number, { text: string; ayah: number; surah: number }>();
        if (ayahLines.length > 0) {
          let maxId = -Infinity;
          for (const l of ayahLines) {
            if (l.first_word_id! < minId) minId = l.first_word_id!;
            if (l.last_word_id! > maxId) maxId = l.last_word_id!;
          }
          try {
            const words = await getWordsForRange(minId, maxId);
            for (const w of words) {
              wordMap.set(w.id, { text: w.text, ayah: w.ayah, surah: w.surah });
            }
          } catch (wordErr) {
            console.error('[usePageData] word fetch failed for page', pageNumber, wordErr);
          }
        }

        const data = rawLines.map((line) => {
          if (line.line_type !== 'ayah' || line.first_word_id == null || line.last_word_id == null) {
            return line;
          }

          const firstEntry = wordMap.get(line.first_word_id);
          const words: string[] = [];
          let lastAyah = firstEntry?.ayah;
          for (let id = line.first_word_id; id <= line.last_word_id; id++) {
            const entry = wordMap.get(id);
            if (entry) {
              words.push(entry.text);
              lastAyah = entry.ayah;
            }
          }
          const wordText = words.join(' ');
          // Use || (not ??) because surah_number is '' (empty string) for non-surah_name lines
          const lineSurah = line.surah_number || firstEntry?.surah;

          const ayahKey = lastAyah && lineSurah ? `${lineSurah}:${lastAyah}` : null;
          const hasRukuMark = wordText.includes('۠');
          return {
            ...line,
            wordText,
            ayahNumber: firstEntry?.ayah,
            endAyahNumber: lastAyah,
            endSurahNumber: lineSurah,
            rukuNumber: hasRukuMark && ayahKey ? RUKU_ENDS[ayahKey] : undefined,
            juzRukuNumber: hasRukuMark && ayahKey ? JUZ_RUKU[ayahKey] : undefined,
            hizbMarker: ayahKey ? JUZ_QUARTER_BOUNDARIES[ayahKey] : undefined,
            sajdaMarker: ayahKey && SAJDA_AYAHS.has(ayahKey) ? true : undefined,
          };
        });

        // Deduplicate hizbMarker and sajdaMarker: keep only the LAST line for each ayah
        // (multi-line ayahs share the same lastAyah, so markers appear on every line).
        // Key includes endSurahNumber to avoid cross-surah collision on the same ayah number.
        const seenHizb = new Set<string>();
        const seenSajda = new Set<string>();
        for (let i = data.length - 1; i >= 0; i--) {
          const line = data[i];
          if (!line.hizbMarker && !line.sajdaMarker) continue;
          const key = `${line.endSurahNumber}:${line.endAyahNumber}`;
          const dropHizb = line.hizbMarker && seenHizb.has(key);
          const dropSajda = line.sajdaMarker && seenSajda.has(key);
          if (line.hizbMarker) seenHizb.add(key);
          if (line.sajdaMarker) seenSajda.add(key);
          if (dropHizb || dropSajda) {
            data[i] = {
              ...line,
              hizbMarker: dropHizb ? undefined : line.hizbMarker,
              sajdaMarker: dropSajda ? undefined : line.sajdaMarker,
            };
          }
        }

        // If a surah starts on this page, show that surah; otherwise fall back to the ongoing surah.
        // Use || (not ??) because surah_number is '' on ayah lines and would not fall through with ??.
        const newSurahLine = rawLines.find(l => l.line_type === 'surah_name' && l.surah_number != null);
        const firstWordEntry = wordMap.get(minId);
        const derivedSurah = newSurahLine?.surah_number || firstWordEntry?.surah || 0;
        // Derive juz from first word's surah+ayah using exact JUZ_STARTS boundaries
        let derivedJuz = 1;
        if (firstWordEntry) {
          const { surah: wSurah, ayah: wAyah } = firstWordEntry;
          for (let i = JUZ_STARTS.length - 1; i >= 0; i--) {
            const [jSurah, jAyah] = JUZ_STARTS[i];
            if (wSurah > jSurah || (wSurah === jSurah && wAyah >= jAyah)) {
              derivedJuz = i + 1;
              break;
            }
          }
        }
        if (!cancelled) {
          setLines(data);
          setPageSurahNumber(derivedSurah);
          setPageJuzNumber(derivedJuz);
        }
      } catch (err) {
        console.error('[usePageData] error loading page', pageNumber, err);
        if (!cancelled) setError(err instanceof Error ? err : new Error(String(err)));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetch();
    return () => { cancelled = true; };
  }, [mode, pageNumber]);

  return { lines, pageSurahNumber, pageJuzNumber, loading, error };
}
