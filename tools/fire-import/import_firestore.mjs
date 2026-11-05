// Writes fire_stations_built.json into Firestore (fire_stations/{id}),
// removes entries no longer in the list (unless an admin added them by hand),
// and sends the packed list to every phone. Needs `firebase login` as an owner.
import fs from 'node:fs';
import { listAll, commit, publishSnapshots } from '../lib/firestore.mjs';

const { fireStations } = JSON.parse(fs.readFileSync(new URL('fire_stations_built.json', import.meta.url), 'utf8'));
const now = new Date().toISOString();
const live = await listAll('fire_stations');
const liveById = new Map(live.map((d) => [d.id, d]));
const ids = new Set(fireStations.map((s) => s.id));
// An admin's edit (newer than the last import, or marked verified) is kept.
const edited = (d) => d && (d.verified || (d.importedAt && d.updatedAt && d.updatedAt > d.importedAt));
const writes = [];
for (const s of fireStations) {
  if (edited(liveById.get(s.id))) continue;
  writes.push({ set: [`fire_stations/${s.id}`, { ...s, published: liveById.get(s.id)?.published ?? true, updatedAt: now, importedAt: now }] });
}
for (const d of live) if (!ids.has(d.id) && d.importedAt) writes.push({ del: `fire_stations/${d.id}` });
await commit(writes);
console.log(`${writes.length} writes (${fireStations.length} entries, ${live.filter(edited).length} admin-edited kept)`);
const published = (await listAll('fire_stations')).filter((d) => d.published);
console.log('content version', await publishSnapshots({ fire_stations: published }), `(${published.length} entries on phones)`);
