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

        // minId/maxId hoisted so they're reachable below for firstWordEntry +
        // the cross-page next-word lookup that decides whether the last ayah on
        // the page ends on this page or continues onto the next.
        let minId = Infinity;
        let maxId = -Infinity;
        const wordMap = new Map<number, { text: string; ayah: number; surah: number }>();
        if (ayahLines.length > 0) {
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

        // Look up the first word of the NEXT page. If it shares an ayah with the
        // last ayah on THIS page, then that ayah continues onto the next page and
        // must NOT be marked as ending here.
        let nextPageFirstAyahKey: string | null = null;
        if (maxId !== -Infinity) {
          try {
            const nextWords = await getWordsForRange(maxId + 1, maxId + 1);
            if (nextWords.length > 0) {
              nextPageFirstAyahKey = `${nextWords[0].surah}:${nextWords[0].ayah}`;
            }
          } catch {
            // If lookup fails, treat as page-end — marker will appear (preferred
            // over missing it).
          }
        }

        const data = rawLines.map((line) => {
          if (line.line_type !== 'ayah' || line.first_word_id == null || line.last_word_id == null) {
            return line;
          }

          const firstEntry = wordMap.get(line.first_word_id);
          const words: string[] = [];
          let lastAyah = firstEntry?.ayah;
          // Group consecutive words by their (surah, ayah) so a line spanning
          // multiple ayahs can render one Pressable per ayah segment.
          const ayahSegments: Array<{ surah: number; ayah: number; text: string }> = [];
          for (let id = line.first_word_id; id <= line.last_word_id; id++) {
            const entry = wordMap.get(id);
            if (entry) {
              words.push(entry.text);
              lastAyah = entry.ayah;
              const last = ayahSegments[ayahSegments.length - 1];
              if (last && last.surah === entry.surah && last.ayah === entry.ayah) {
                last.text += ' ' + entry.text;
              } else {
                ayahSegments.push({ surah: entry.surah, ayah: entry.ayah, text: entry.text });
              }
            }
          }
          const wordText = words.join(' ');
          // Use || (not ??) because surah_number is '' (empty string) for non-surah_name lines
          const lineSurah = line.surah_number || firstEntry?.surah;

          return {
            ...line,
            wordText,
            ayahSegments,
            ayahNumber: firstEntry?.ayah,
            endAyahNumber: lastAyah,
            endSurahNumber: lineSurah,
          };
        });

        // Mark the first line of each MID-SURAH Juz start (ayah != 1) so it
        // can render with inverted styling. New-surah Juz starts already get
        // visual treatment via the basmallah row, so we skip ayah==1 entries.
        const midSurahJuzKeys = new Set(
          JUZ_STARTS.filter(([, a]) => a !== 1).map(([s, a]) => `${s}:${a}`)
        );
        for (let i = 0; i < data.length; i++) {
          const line = data[i];
          if (line.line_type !== 'ayah') continue;
          const firstAyah = line.ayahNumber;
          const lineSurah = line.endSurahNumber;
          if (!firstAyah || !lineSurah) continue;
          if (!midSurahJuzKeys.has(`${lineSurah}:${firstAyah}`)) continue;
          // The ayah only "starts here" if the previous line was either a
          // non-ayah line, a different surah, or ended a different ayah.
          const prev = i > 0 ? data[i - 1] : null;
          const startsHere =
            !prev ||
            prev.line_type !== 'ayah' ||
            prev.endSurahNumber !== lineSurah ||
            prev.endAyahNumber !== firstAyah;
          if (startsHere) {
            data[i] = { ...line, isJuzFirstLine: true };
          }
        }

        // Place sidebar markers (ruku / juz-ruku / hizb-quarter / sajdah) on the
        // line where the boundary ayah ENDS. Earlier logic put them on whichever
        // line had `lastAyah == X`, which is wrong when ayah X ends mid-line on a
        // later line (lastAyah of that later line is X+1, so X's end is missed).
        //
        // For each ayah segment on a line, an ayah is considered "ended on this
        // line" if no LATER line on the page contains it. The last line gets a
        // cross-page check via nextPageFirstAyahKey so that ayahs continuing onto
        // the next page don't get a spurious marker here.
        for (let i = 0; i < data.length; i++) {
          const line = data[i];
          if (line.line_type !== 'ayah') continue;
          const segs = (line as any).ayahSegments as Array<{ surah: number; ayah: number; text: string }> | undefined;
          if (!segs || segs.length === 0) continue;

          let rukuNumber: number | undefined;
          let juzRukuNumber: number | undefined;
          let hizbMarker: string | undefined;
          let sajdaMarker: boolean | undefined;

          for (const seg of segs) {
            const key = `${seg.surah}:${seg.ayah}`;

            let endsHere = true;
            for (let j = i + 1; j < data.length; j++) {
              const lj = data[j];
              if (lj.line_type !== 'ayah') continue;
              const ljSegs = (lj as any).ayahSegments as typeof segs | undefined;
              if (ljSegs && ljSegs.some((s) => s.surah === seg.surah && s.ayah === seg.ayah)) {
                endsHere = false;
                break;
              }
            }
            // If still considered "ends here" but it's the last appearance on the
            // page AND the next page begins with the same ayah, the ayah continues.
            if (endsHere && nextPageFirstAyahKey === key) {
              endsHere = false;
            }
            if (!endsHere) continue;

            if (RUKU_ENDS[key] !== undefined) rukuNumber = RUKU_ENDS[key];
            if (JUZ_RUKU[key] !== undefined) juzRukuNumber = JUZ_RUKU[key];
            if (JUZ_QUARTER_BOUNDARIES[key]) hizbMarker = JUZ_QUARTER_BOUNDARIES[key];
            if (SAJDA_AYAHS.has(key)) sajdaMarker = true;
          }

          data[i] = { ...line, rukuNumber, juzRukuNumber, hizbMarker, sajdaMarker };
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
