// Fetches all 6236 verses from quran.com API and computes the
// JUZ_QUARTER_BOUNDARIES constant using TRADITIONAL mushaf rub'-al-hizb
// boundaries: each Juz has 8 rub' al-hizb segments. Positions 2, 4, 6 of
// those segments correspond to Juz 1/4, 1/2, 3/4 boundaries.
//
// The marker key is the LAST verse of each Juz quarter (matching the
// convention of HIZB_QUARTER_ENDS).
//
// Run: node scripts/build-juz-quarters.mjs > /tmp/juz-quarters.txt

const UA = { 'User-Agent': 'Mozilla/5.0 quran-app build script' };

async function fetchPage(chapter, page) {
  const url = `https://api.quran.com/api/v4/verses/by_chapter/${chapter}?per_page=300&page=${page}&fields=juz_number,rub_el_hizb_number,verse_key`;
  const res = await fetch(url, { headers: UA });
  if (!res.ok) throw new Error(`HTTP ${res.status} chapter ${chapter} page ${page}`);
  return res.json();
}

async function fetchChapter(chapter) {
  const all = [];
  let page = 1;
  while (true) {
    const data = await fetchPage(chapter, page);
    all.push(...data.verses);
    if (!data.pagination || data.pagination.next_page == null) break;
    page = data.pagination.next_page;
  }
  return all;
}

async function main() {
  const verses = [];
  for (let c = 1; c <= 114; c++) {
    process.stderr.write(`fetching chapter ${c}...\r`);
    const chap = await fetchChapter(c);
    verses.push(...chap);
  }
  process.stderr.write(`\nfetched ${verses.length} verses\n`);

  // For each Juz, find the last verse of each rub'-al-hizb segment within it.
  // A new rub' begins when rub_el_hizb_number changes; the previous verse is
  // the LAST verse of the previous rub'.
  const juzRubEnds = new Map(); // juz -> array of {key, rub}
  for (let i = 0; i < verses.length; i++) {
    const v = verses[i];
    const next = verses[i + 1];
    const isLastOfRub = !next
      || next.rub_el_hizb_number !== v.rub_el_hizb_number
      || next.juz_number !== v.juz_number;
    if (isLastOfRub) {
      if (!juzRubEnds.has(v.juz_number)) juzRubEnds.set(v.juz_number, []);
      juzRubEnds.get(v.juz_number).push({ key: v.verse_key, rub: v.rub_el_hizb_number });
    }
  }

  console.log('export const JUZ_QUARTER_BOUNDARIES: Record<string, string> = {');
  for (let j = 1; j <= 30; j++) {
    const ends = juzRubEnds.get(j) || [];
    if (ends.length < 8) {
      console.error(`Juz ${j}: only ${ends.length} rub-ends (expected 8)`);
      continue;
    }
    // 8 segments per Juz; take ends at indices 1, 3, 5 (0-indexed) = 2nd, 4th, 6th rub end.
    // These correspond to the LAST verse of Juz 1/4, 1/2, 3/4 segments.
    console.log(`  // Juz ${j}`);
    console.log(`  '${ends[1].key}': 'ربع',`);
    console.log(`  '${ends[3].key}': 'نصف',`);
    console.log(`  '${ends[5].key}': 'ثلث',`);
  }
  console.log('};');
}

main().catch((e) => { console.error(e); process.exit(1); });
