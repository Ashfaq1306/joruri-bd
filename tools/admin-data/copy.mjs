// Copies the DGDA lists that are built into the app (medicines and the
// pharmacy register) next to the admin website, so its Medicines and
// Pharmacies pages can search them and correct or hide an entry.
// Runs before every hosting deploy (firebase.json → hosting.predeploy);
// the copies (admin/data/) are not kept in git.
import fs from 'node:fs';

const seed = new URL('../../apps/mobile/assets/seed/', import.meta.url);
const out = new URL('../../admin/data/', import.meta.url);
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(new URL('pharmacies/', out), { recursive: true });
fs.copyFileSync(new URL('medicines.json', seed), new URL('medicines.json', out));
let n = 0;
for (const f of fs.readdirSync(new URL('pharmacies/', seed))) {
  if (!f.endsWith('.json')) continue;
  fs.copyFileSync(new URL(`pharmacies/${f}`, seed), new URL(`pharmacies/${f}`, out));
  n++;
}
console.log(`admin/data: medicines.json and ${n} district pharmacy lists copied`);
