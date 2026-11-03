// Downloads DGDA registered allopathic medicines and their approved prices from
// the DGDA medicine price search (http://180.211.137.202:9310/Allopathic/).
// 1) medicine list (~41,000 brands) → medicines_list.json
// 2) one price page per brand, 3 at a time → prices.jsonl (resumable)
import fs from 'node:fs';
const UA = 'Mozilla/5.0 (JoruriBD emergency app data import; contact ashfaqur87654@gmail.com)';
const B = 'http://180.211.137.202:9310/Allopathic';
const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));
const strip = (s) => String(s ?? '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
async function get(url) {
  for (let attempt = 1; ; attempt++) {
    try {
      const r = await fetch(url, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(90000) });
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return await r.text();
    } catch (e) { if (attempt >= 5) throw e; await sleep(4000 * attempt); }
  }
}

if (!fs.existsSync('medicines_list.json')) {
  const all = [];
  for (let start = 0, total = Infinity; start < total; start += 5000) {
    const j = JSON.parse(await get(`${B}/Medicine_Information_Ajax.php?action=list&draw=1&start=${start}&length=5000`));
    total = j.recordsTotal;
    for (const a of j.data) {
      const href = (String(a[6]).match(/href="\?([^"]+)"/) || [])[1];
      all.push({ company: strip(a[1]), brand: strip(a[2]), genericStrength: strip(a[3]), form: strip(a[4]), dar: strip(a[5]), href });
    }
    console.log('list', all.length, '/', total);
    await sleep(1000);
  }
  fs.writeFileSync('medicines_list.json', JSON.stringify(all));
}
const list = JSON.parse(fs.readFileSync('medicines_list.json', 'utf8'));
const done = new Set();
if (fs.existsSync('prices.jsonl')) for (const l of fs.readFileSync('prices.jsonl', 'utf8').split('\n')) if (l) done.add(JSON.parse(l).href);
const todo = list.filter((m) => m.href && !done.has(m.href));
console.log('prices to fetch', todo.length, 'already', done.size);

function parse(html) {
  const field = (label) => { const m = html.match(new RegExp(label + '[^<]*<\/b><\/span>([^<]*)<', 'i')); return m ? strip(m[1]).replace(/\+/g, ' ') : ''; };
  const packs = [];
  const tbody = (html.match(/Unit Price[\s\S]*?<\/tr>([\s\S]*?)<\/table>/i) || [])[1] || '';
  for (const tr of tbody.split(/<tr/i).slice(1)) {
    const td = [...tr.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((x) => strip(x[1]));
    if (td.length >= 3 && /\d/.test(td[2])) packs.push({ pack: td[1], unitPrice: td[2] });
  }
  return { generic: field('Generic Name'), strength: field('STRENGTH'), packs };
}
let n = 0, failed = 0;
async function worker() {
  while (todo.length) {
    const m = todo.shift();
    try {
      const rec = { href: m.href, ...parse(await get(`${B}/?${m.href}`)) };
      fs.appendFileSync('prices.jsonl', JSON.stringify(rec) + '\n');
    } catch (e) { failed++; }
    if (++n % 500 === 0) console.log(new Date().toISOString().slice(11, 19), 'prices', n, 'left', todo.length, 'failed', failed);
    await sleep(150);
  }
}
await Promise.all([worker(), worker(), worker()]);
console.log('DONE prices', n, 'failed', failed);
