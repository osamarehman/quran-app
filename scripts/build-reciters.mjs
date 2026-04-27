// Fetches all available reciters from quran.com and derives a URL template
// for each one by sampling a single ayah audio URL. Output goes to stdout
// as a TypeScript-ready RECITERS array.
//
// Run: node scripts/build-reciters.mjs > /tmp/reciters.txt

const UA = { 'User-Agent': 'Mozilla/5.0 quran-app build script' };

async function fetchJSON(url) {
  const res = await fetch(url, { headers: UA });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
  return res.json();
}

function buildTemplate(rawUrl) {
  // Sample url ends in NNNAAA.mp3 (e.g. 002001.mp3). Replace with token.
  const m = rawUrl.match(/^(.*\/)\d{6}\.mp3$/);
  if (!m) throw new Error(`Unrecognised URL shape: ${rawUrl}`);
  const prefix = m[1];
  if (prefix.startsWith('//')) {
    return `https:${prefix}{NNNAAA}.mp3`;
  }
  return `https://verses.quran.com/${prefix}{NNNAAA}.mp3`;
}

async function probe(id) {
  const data = await fetchJSON(`https://api.quran.com/api/v4/recitations/${id}/by_ayah/2:1`);
  const url = data.audio_files?.[0]?.url;
  if (!url) throw new Error(`no audio for id ${id}`);
  return buildTemplate(url);
}

async function head(url) {
  const res = await fetch(url, { method: 'HEAD', headers: UA });
  return res.status;
}

async function main() {
  const list = (await fetchJSON('https://api.quran.com/api/v4/resources/recitations')).recitations || [];
  process.stderr.write(`got ${list.length} reciters\n`);

  const out = [];
  for (const r of list) {
    try {
      const tpl = await probe(r.id);
      const sample = tpl.replace('{NNNAAA}', '002001');
      const code = await head(sample);
      const ok = code === 200;
      const label = r.style ? `${r.reciter_name} (${r.style})` : r.reciter_name;
      out.push({ id: r.id, label, urlTemplate: tpl, ok });
      process.stderr.write(`id=${r.id} ${ok ? 'OK' : 'FAIL'} ${tpl}\n`);
    } catch (e) {
      process.stderr.write(`id=${r.id} ERROR ${e.message}\n`);
    }
  }

  console.log('export const RECITERS = [');
  for (const r of out) {
    if (!r.ok) continue;
    const lbl = r.label.replace(/'/g, "\\'");
    console.log(`  { id: ${r.id}, label: '${lbl}', urlTemplate: '${r.urlTemplate}' },`);
  }
  console.log('] as const;');
}

main().catch((e) => { console.error(e); process.exit(1); });
