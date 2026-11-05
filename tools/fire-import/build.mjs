// source/fire_stations.txt → fire_stations_built.json + report.txt.
// `node build.mjs --install` also copies the list into the app
// (apps/mobile/assets/seed/fire_stations.json).
//
// Every number is checked. A number that is misprinted (wrong length, old
// Dhaka land line) or that clashes with another entry's number is left
// blank and marked `needsCheck`, so the app never dials a guess; the app
// shows "number being checked, call 999 or 102" for those. Fix them on the
// admin website (Fire stations → edit) once someone has confirmed them.
import fs from 'node:fs';

const here = (p) => new URL(p, import.meta.url);
const TODAY = '2026-11-05';

// Districts and divisions: the admin website's copy of BdLocations.
const LOC = JSON.parse(/const LOC = (\{.*?\});\r?\n/s.exec(fs.readFileSync(here('../../admin/app.js'), 'utf8'))[1]);
const DISTRICT = new Map(LOC.districts.map((d) => [d.id, d]));
const DIVISION = new Map(LOC.divisions.map((d) => [d.id, d]));

// Decided by reading the lists side by side (see README.md). Key: district|English name.
const HOLD = {
  'narayanganj|Deputy Assistant Director, Narayanganj Zone-2': 'Printed with the same number as Dhaka Zone-2 (01901-020705).',
  'khagrachhari|Deputy Assistant Director, Khagrachhari': 'Printed with the same number as Chattogram Zone-3 (01901-021508).',
  'jhenaidah|Kaliganj': 'Printed with the same number as Harinakunda (01901-022852).',
  'gaibandha|Gaibandha': 'Printed with the same number as Kurigram Fire Station (01901-023337), which fits the Kurigram series.',
  'mymensingh|Agricultural University (BAU)': 'Printed with the same number as Muktagachha (01901-024225).',
  'khulna|Khulna Land-cum-River': 'Printed 01301-022748: probably 01901-022748 (every other Khulna station is 01901-0227xx).',
  'jashore|Monirampur': 'Printed 01740-322834: probably 01901-022834 (every other Jashore station is 01901-0228xx).',
};
// What the misprinted numbers probably are (report only, never used).
const GUESS = {
  'chattogram|Deputy Director, Chattogram Division': '01901-020110',
  'chattogram|Deputy Assistant Director, Chattogram Zone-1': '01901-021506',
  'chattogram|Agrabad': '01901-021540',
  'brahmanbaria|Deputy Assistant Director, Brahmanbaria': '01901-021514',
  'chandpur|Deputy Assistant Director, Chandpur': '01901-021515',
  'noakhali|Senbagh': '01901-021801',
};

const bnDigits = (s) => s.replace(/[০-৯]/g, (c) => String('০১২৩৪৫৬৭৮৯'.indexOf(c)));
const slug = (s) => s.toLowerCase().replace(/&/g, 'and').replace(/['’()]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const show = (d) => (d.length === 11 ? `${d.slice(0, 5)}-${d.slice(5)}` : d);

function normalise(printed) {
  const d = bnDigits(printed).replace(/\D/g, '');
  if (/^01[3-9]\d{8}$/.test(d)) return { phone: '+880' + d.slice(1), digits: d };
  if (/^02\d{8,9}$/.test(d)) return { phone: '+880' + d.slice(1), digits: d };
  const why = /^02\d{7}$/.test(d) ? 'old 7-digit Dhaka land line (changed in 2018)' : `${d.length} digits`;
  return { phone: '', digits: d, problem: `Printed "${printed}" (${why}).` };
}

const rows = [];
let district = null;
const report = [];
for (const [i, raw] of fs.readFileSync(here('source/fire_stations.txt'), 'utf8').split(/\r?\n/).entries()) {
  const line = raw.trim();
  if (line.startsWith('## ')) {
    district = line.slice(3).trim();
    if (!DISTRICT.has(district)) throw new Error(`line ${i + 1}: unknown district ${district}`);
    continue;
  }
  if (!line || line.startsWith('#')) continue;
  const [kind, bn, en, printed] = line.split('|').map((x) => x.trim());
  if (!['S', 'O'].includes(kind) || !bn || !en || !printed || !district) throw new Error(`line ${i + 1}: bad row: ${line}`);
  rows.push({ kind, bn, en, printed, district, line: i + 1 });
}

// Exact repeats (same district, name and number) are printed twice: keep one.
const seen = new Set();
const unique = rows.filter((r) => {
  const k = `${r.district}|${r.en}|${bnDigits(r.printed).replace(/\D/g, '')}`;
  if (seen.has(k)) { report.push(`Repeated row dropped: ${r.en} (${r.district}), line ${r.line}`); return false; }
  seen.add(k);
  return true;
});

const stations = [];
const ids = new Set();
for (const r of unique) {
  const key = `${r.district}|${r.en}`;
  const d = DISTRICT.get(r.district);
  const division = DIVISION.get(d.divisionId);
  const office = r.kind === 'O';
  const n = normalise(r.printed);
  let needsCheck = n.problem || '';
  if (HOLD[key]) needsCheck = HOLD[key];
  if (GUESS[key]) needsCheck += ` Probably ${GUESS[key]}.`;
  let id = `fs-${r.district}-${slug(r.en)}`;
  for (let k = 2; ids.has(id); k++) id = `fs-${r.district}-${slug(r.en)}-${k}`;
  ids.add(id);
  stations.push({
    id,
    service: 'fire',
    name: office ? r.en : `${r.en} Fire Station`,
    nameBn: office ? r.bn : `${r.bn} ফায়ার স্টেশন`,
    districtId: r.district,
    phone: needsCheck ? '' : n.phone,
    ...(office ? { office: true } : {}),
    open24h: !office || /control/i.test(r.en),
    source: `Fire Service and Civil Defence, ${division.en} division list of station and office numbers (received ${TODAY})`,
    checkedOn: TODAY,
    nameInSource: r.bn,
    printedNumber: r.printed,
    ...(needsCheck ? { needsCheck: needsCheck.trim() } : {}),
  });
}

// Any number still used by two entries is a mistake we have not decided on.
const byPhone = new Map();
for (const s of stations) if (s.phone) byPhone.set(s.phone, [...(byPhone.get(s.phone) || []), s]);
for (const [p, list] of byPhone) if (list.length > 1) throw new Error(`${p} is on ${list.map((s) => s.id).join(', ')}: decide in HOLD`);

const held = stations.filter((s) => s.needsCheck);
const outside = stations.filter((s) => s.phone && !/^\+88019010[0-9]{5}$/.test(s.phone));
const perDivision = {};
for (const s of stations) {
  const div = DISTRICT.get(s.districtId).divisionId;
  perDivision[div] = (perDivision[div] || 0) + 1;
}
const missingDistricts = LOC.districts.filter((d) => !stations.some((s) => s.districtId === d.id && !s.office));
const lines = [
  `Fire Service list built ${new Date().toISOString()}`,
  `${stations.length} entries: ${stations.filter((s) => !s.office).length} fire stations, ${stations.filter((s) => s.office).length} offices; ${new Set(stations.map((s) => s.districtId)).size} of 64 districts`,
  `Per division: ${Object.entries(perDivision).map(([k, v]) => `${k} ${v}`).join(', ')}`,
  missingDistricts.length ? `Districts without a fire station: ${missingDistricts.map((d) => d.en).join(', ')}` : 'Every district has at least one fire station.',
  '',
  `Number left blank until someone checks it (${held.length}):`,
  ...held.map((s) => `  ${s.name} (${DISTRICT.get(s.districtId).en}): ${s.needsCheck}`),
  '',
  `Kept, but outside the Fire Service's 01901-02xxxx series (${outside.length}); worth a call to confirm:`,
  ...outside.map((s) => `  ${s.name} (${DISTRICT.get(s.districtId).en}): ${show('0' + s.phone.slice(4))}`),
  '',
  ...report,
];
fs.writeFileSync(here('report.txt'), lines.join('\n') + '\n');
const out = {
  schemaVersion: 1,
  updatedAt: TODAY,
  source: 'Fire Service and Civil Defence: station and office numbers, one list per division (received 2026-11-05)',
  fireStations: stations,
};
fs.writeFileSync(here('fire_stations_built.json'), JSON.stringify(out, null, 1) + '\n');
if (process.argv.includes('--install')) {
  fs.writeFileSync(here('../../apps/mobile/assets/seed/fire_stations.json'), JSON.stringify(out) + '\n');
  console.log('installed into apps/mobile/assets/seed/fire_stations.json');
}
console.log(lines.slice(0, 4).join('\n'));
console.log(`${held.length} numbers held for checking, ${outside.length} outside the series (report.txt)`);
