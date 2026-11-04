// Minimal Firestore REST client for the data tools, signed in with the
// Firebase CLI's login (`firebase login` as a project owner). No secrets
// are stored here: the refresh token is read from the CLI's own config.
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

export const PROJECT = 'joruri-bd';
const DOCS = `projects/${PROJECT}/databases/(default)/documents`;
const API = `https://firestore.googleapis.com/v1/${DOCS}`;
// The Firebase CLI's public OAuth client (the same one firebase-tools uses).
const CLI_CLIENT = { id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com', secret: 'j9iVZfS8kkCEFUPaAeJV0sAi' };

let tok = null;
async function token() {
  const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
  const r = await fetch('https://oauth2.googleapis.com/token', { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: cfg.tokens.refresh_token, client_id: CLI_CLIENT.id, client_secret: CLI_CLIENT.secret }) });
  const j = await r.json();
  if (!j.access_token) throw new Error('Not signed in: run `firebase login` first');
  return j.access_token;
}
const H = async () => ({ authorization: `Bearer ${tok ??= await token()}`, 'content-type': 'application/json' });

export function val(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).filter(([, x]) => x !== undefined).map(([k, x]) => [k, val(x)])) } };
}
export function plain(v) {
  if ('stringValue' in v) return v.stringValue; if ('integerValue' in v) return Number(v.integerValue); if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue; if ('nullValue' in v) return null; if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(plain);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, plain(x)]));
  return null;
}
const fields = (o) => val(o).mapValue.fields;

async function call(url, init = {}) {
  for (let attempt = 1; ; attempt++) {
    const r = await fetch(url, { ...init, headers: await H() });
    if (r.ok) return r.status === 204 ? null : r.json();
    const t = await r.text();
    if (r.status === 404 && init.method !== 'POST') return null;
    if (r.status === 401) tok = await token();
    if (attempt >= 4) throw new Error(`${r.status} ${t.slice(0, 300)}`);
    await new Promise((ok) => setTimeout(ok, 2000 * attempt));
  }
}
export async function getDoc(p) { const d = await call(`${API}/${p}`); return d ? { ...plain({ mapValue: { fields: d.fields || {} } }), id: d.name.split('/').pop() } : null; }
export async function listAll(col) {
  const out = []; let pageToken = '';
  do {
    const r = await call(`${API}/${col}?pageSize=300${pageToken ? '&pageToken=' + pageToken : ''}`);
    for (const d of r?.documents || []) out.push({ ...plain({ mapValue: { fields: d.fields || {} } }), id: d.name.split('/').pop() });
    pageToken = r?.nextPageToken || '';
  } while (pageToken);
  return out;
}
/** writes: [{set: [path, data]} | {merge: [path, data]} | {del: path} | {increment: [path, field, by]}] */
export async function commit(writes) {
  for (let i = 0; i < writes.length; i += 400) {
    await call(`${API.replace('/documents', '')}/documents:commit`, { method: 'POST', body: JSON.stringify({ writes: writes.slice(i, i + 400).map((w) => {
      if (w.set) return { update: { name: `${DOCS}/${w.set[0]}`, fields: fields(w.set[1]) } };
      if (w.merge) return { update: { name: `${DOCS}/${w.merge[0]}`, fields: fields(w.merge[1]) }, updateMask: { fieldPaths: Object.keys(w.merge[1]).map((k) => '`' + k + '`') } };
      if (w.del) return { delete: `${DOCS}/${w.del}` };
      if (w.increment) return { transform: { document: `${DOCS}/${w.increment[0]}`, fieldTransforms: [{ fieldPath: w.increment[1], increment: val(w.increment[2]) }] } };
      throw new Error('bad write');
    }) }) });
  }
}

/**
 * Same packing as the admin website's publishSnapshots (admin/backend-firebase.js):
 * each published list → snapshots/{col}-{n} (≤ 900 KB each), then meta/content
 * gets new chunk counts + stamps for those lists and version + 1, so every
 * phone downloads the change (only the lists whose stamp changed).
 */
export async function publishSnapshots(lists) {
  const meta = (await getDoc('meta/content')) || {};
  const oldChunks = meta.chunks || {}; const chunks = { ...oldChunks }; const stamps = { ...(meta.stamps || {}) };
  const now = new Date().toISOString(); const writes = [];
  for (const [col, items] of Object.entries(lists)) {
    const parts = []; let cur = []; let size = 2;
    for (const item of items) {
      const n = Buffer.byteLength(JSON.stringify(item)) + 1;
      if (cur.length && size + n > 900000) { parts.push(cur); cur = []; size = 2; }
      cur.push(item); size += n;
    }
    if (cur.length || !parts.length) parts.push(cur);
    parts.forEach((p, i) => writes.push({ set: [`snapshots/${col}-${i}`, { json: JSON.stringify(p), part: i, total: parts.length, updatedAt: now }] }));
    for (let i = parts.length; i < (oldChunks[col] || 0); i++) writes.push({ del: `snapshots/${col}-${i}` });
    chunks[col] = parts.length; stamps[col] = now;
  }
  // Snapshots are written in their own commits first (each can be ~900 KB).
  for (const w of writes) await commit([w]);
  await commit([{ merge: ['meta/content', { chunks, stamps, updatedAt: now }] }, { increment: ['meta/content', 'version', 1] }]);
  return (await getDoc('meta/content')).version;
}
