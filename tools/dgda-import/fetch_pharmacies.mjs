// Downloads the DGDA allopathic retail pharmacy register (dgdagov.info → Pharmacies →
// Allopathic Retail Pharmacy). ~170,000 rows in pages of 5,000 → pharmacies_raw.jsonl.
// Resumable: re-run to continue. Personal fields (pharmacist, proprietor, NID) are
// dropped here and never written to disk.
import fs from 'node:fs';
const UA = 'Mozilla/5.0 (JoruriBD emergency app data import; contact ashfaqur87654@gmail.com)';
const URL = 'https://dgdagov.info/administrator/components/com_jcode/source/serverProcessing.php';
const OUT = 'pharmacies_raw.jsonl', PAGE = 5000;
const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));
const strip = (s) => String(s ?? '').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();

async function page(start, length = PAGE) {
  const body = new URLSearchParams({ action: 'getPharmacyDataView', Ptype: 'Al', DistrictId: '', UpazilaId: '',
    validuptoDateId: '', sEcho: '1', iDisplayStart: String(start), iDisplayLength: String(length), iColumns: '10' });
  for (let attempt = 1; ; attempt++) {
    try {
      const r = await fetch(URL, { method: 'POST', body, headers: { 'user-agent': UA }, signal: AbortSignal.timeout(120000) });
      if (!r.ok) throw new Error('HTTP ' + r.status);
      // Some rows contain raw tabs/newlines or stray backslashes, which is not valid JSON.
      const text = (await r.text()).replace(/[\u0000-\u001f]/g, ' ').replace(/\\(?!["\\/bfnrtu])/g, '\\\\');
      try { return JSON.parse(text); } catch (e) { e.badJson = true; throw e; }
    } catch (e) { if (e.badJson || attempt >= 5) throw e; await sleep(5000 * attempt); }
  }
}
const done = fs.existsSync(OUT) ? fs.readFileSync(OUT, 'utf8').split('\n').filter(Boolean).length : 0;
let start = Math.floor(done / PAGE) * PAGE;
if (done % PAGE) { // drop a partial page so it is fetched again
  fs.writeFileSync(OUT, fs.readFileSync(OUT, 'utf8').split('\n').filter(Boolean).slice(0, start).map((l) => l + '\n').join(''));
}
// A page with a broken row is split until only that row is skipped.
async function rowsOf(start, length) {
  try {
    const j = await page(start, length);
    total = j.iTotalRecords;
    return j.aaData;
  } catch (e) {
    if (!e.badJson) throw e;
    if (length === 1) { console.log('skipped unreadable row at', start); return [null]; }
    const half = Math.ceil(length / 10);
    const out = [];
    for (let s = start; s < start + length; s += half) out.push(...await rowsOf(s, Math.min(half, start + length - s)));
    return out;
  }
}
let total = Infinity;
while (start < total) {
  const data = await rowsOf(start, PAGE);
  if (!data.length) break;
  const rows = data.map((a) => a && ({
    dgdaId: a[0], district: strip(a[2]), upazila: strip(a[3]), name: strip(a[4]), licence: strip(a[5]),
    newLicence: strip(a[6]), renewed: strip(a[7]), validUpto: strip(a[8]), division: strip(a[10]),
    address: strip(a[13]), phone: strip(unescape(a[14] ?? '')),
  }));
  if (!rows.length) break;
  fs.appendFileSync(OUT, rows.map((r) => JSON.stringify(r) + '\n').join(''));
  start += rows.length;
  console.log(new Date().toISOString().slice(11, 19), start, '/', total);
  await sleep(1500);
}
console.log('DONE');
