// Writes hospitals_built.json into Firestore (hospitals/{id}), then rebuilds
// the packed snapshots for every content list and updates meta/content
// (same format as the admin website's publishSnapshots).
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';
const P = 'projects/joruri-bd/databases/(default)/documents';
const API = 'https://firestore.googleapis.com/v1/projects/joruri-bd/databases/(default)/documents';
const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
async function token() {
  return (await (await fetch('https://oauth2.googleapis.com/token', { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: cfg.tokens.refresh_token,
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com', client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi' }) })).json()).access_token;
}
let tok = await token();
const H = () => ({ authorization: `Bearer ${tok}`, 'content-type': 'application/json' });

function val(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).filter(([, x]) => x !== undefined).map(([k, x]) => [k, val(x)])) } };
}
function plain(v) {
  if ('stringValue' in v) return v.stringValue; if ('integerValue' in v) return Number(v.integerValue); if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue; if ('nullValue' in v) return null; if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(plain);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, plain(x)]));
  return null;
}
async function commit(writes) {
  for (let attempt = 1; ; attempt++) {
    const r = await fetch(`${API.replace('/documents', '')}/documents:commit`, { method: 'POST', headers: H(), body: JSON.stringify({ writes }) });
    if (r.ok) return;
    const t = await r.text();
    if (r.status === 401) tok = await token();
    if (attempt >= 4) throw new Error(`${r.status} ${t.slice(0, 300)}`);
    await new Promise((ok) => setTimeout(ok, 2000 * attempt));
  }
}
async function listAll(col) {
  const out = []; let pageToken = '';
  do {
    const r = await (await fetch(`${API}/${col}?pageSize=300${pageToken ? '&pageToken=' + pageToken : ''}`, { headers: H() })).json();
    for (const d of r.documents || []) out.push({ ...plain({ mapValue: { fields: d.fields || {} } }), id: d.name.split('/').pop() });
    pageToken = r.nextPageToken || '';
  } while (pageToken);
  return out;
}

const hospitals = JSON.parse(fs.readFileSync('hospitals_built.json', 'utf8'));
const now = new Date().toISOString();
const only = process.argv[2]; // "snapshots" = skip the per-document write

if (only !== 'snapshots') {
  for (let i = 0; i < hospitals.length; i += 400) {
    await commit(hospitals.slice(i, i + 400).map((h) => ({ update: { name: `${P}/hospitals/${h.id}`, fields: val({ ...h, updatedAt: now }).mapValue.fields } })));
    process.stdout.write(`hospitals ${Math.min(i + 400, hospitals.length)}/${hospitals.length}\n`);
  }
}

// Snapshots for every content list (hospitals from the built file, others from Firestore).
const lists = {
  hospitals: hospitals.filter((h) => h.published),
  emergency_numbers: (await listAll('emergency_numbers')).filter((x) => x.published),
  guides: (await listAll('guides')).filter((x) => x.published),
  pharmacies: (await listAll('pharmacies')).filter((x) => x.published),
  announcements: (await listAll('announcements')).filter((x) => x.published),
};
const metaDoc = await (await fetch(`${API}/meta/content`, { headers: H() })).json();
const oldChunks = metaDoc.fields?.chunks ? plain(metaDoc.fields.chunks) : {};
const chunks = {}; const stamps = {};
for (const [col, items] of Object.entries(lists)) {
  const parts = []; let cur = []; let size = 2;
  for (const item of items) {
    const n = Buffer.byteLength(JSON.stringify(item)) + 1;
    if (cur.length && size + n > 900000) { parts.push(cur); cur = []; size = 2; }
    cur.push(item); size += n;
  }
  if (cur.length || !parts.length) parts.push(cur);
  for (let i = 0; i < parts.length; i++) {
    await commit([{ update: { name: `${P}/snapshots/${col}-${i}`, fields: val({ json: JSON.stringify(parts[i]), part: i, total: parts.length, updatedAt: now }).mapValue.fields } }]);
  }
  for (let i = parts.length; i < (oldChunks[col] || 0); i++) await commit([{ delete: `${P}/snapshots/${col}-${i}` }]);
  chunks[col] = parts.length; stamps[col] = now;
  console.log(`snapshot ${col}: ${items.length} items in ${parts.length} part(s)`);
}
await commit([
  { update: { name: `${P}/meta/content`, fields: val({ chunks, stamps, updatedAt: now }).mapValue.fields },
    updateMask: { fieldPaths: ['chunks', 'stamps', 'updatedAt'] } },
  { transform: { document: `${P}/meta/content`, fieldTransforms: [{ fieldPath: 'version', increment: { integerValue: '1' } }] } },
]);
console.log('meta/content updated');
