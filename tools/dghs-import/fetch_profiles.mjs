// Fetches each facility profile (address, land phones, location, website, beds).
// Resumable: appends one JSON line per facility to profiles.jsonl.
import fs from 'node:fs';
import { parse } from './parse_profile.mjs';
const UA = 'Mozilla/5.0 (JoruriBD emergency app data import; contact ashfaqur87654@gmail.com)';
const list = JSON.parse(fs.readFileSync('dghs_list.json', 'utf8'));
const done = new Set();
if (fs.existsSync('profiles.jsonl')) for (const l of fs.readFileSync('profiles.jsonl', 'utf8').split('\n')) if (l) done.add(JSON.parse(l).id);
const todo = list.filter((r) => !done.has(r.id));
console.log('to fetch', todo.length, 'already', done.size);

const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));
let n = 0, failed = 0;
async function worker() {
  while (todo.length) {
    const r = todo.shift();
    const url = `https://hris.mohfw.gov.bd/public/facility-registry/facilities/${r.id}/profile?tab=detailed-information`;
    let rec = null;
    for (let attempt = 1; attempt <= 4 && !rec; attempt++) {
      try {
        const res = await fetch(url, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(45000) });
        if (!res.ok) throw new Error('HTTP ' + res.status);
        rec = { id: r.id, ...parse(await res.text()) };
      } catch (e) { await sleep(4000 * attempt); }
    }
    if (!rec) { failed++; continue; }
    fs.appendFileSync('profiles.jsonl', JSON.stringify(rec) + '\n');
    if (++n % 200 === 0) console.log(new Date().toISOString().slice(11, 19), 'fetched', n, 'left', todo.length, 'failed', failed);
    await sleep(250);
  }
}
await Promise.all([worker(), worker(), worker()]);
console.log('DONE fetched', n, 'failed', failed);
