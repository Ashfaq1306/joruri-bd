// Builds the app's police station list (apps/mobile/assets/seed/police_stations.json)
// from the OC numbers in source/thana-services.pdf (rows extracted by
// extract_pdf.py into thana_rows.json) plus addresses/e-mails from the DMP
// website (source/dmp_find_your_local_police.html).
//
//   node build.mjs            → police_stations_built.json + report.txt
//   node build.mjs --install  → also copies it into the app's bundled data
import fs from 'node:fs';
import { DISTRICT_OF_BLOCK, BLOCK_EXCEPTIONS, SKIP, NAMES, EN_FIX, BN_FIX } from './names.mjs';

const here = (p) => new URL(p, import.meta.url);
const rows = JSON.parse(fs.readFileSync(here('thana_rows.json'), 'utf8'));
const hospitals = JSON.parse(fs.readFileSync(here('../../apps/mobile/assets/seed/hospitals.json'), 'utf8')).hospitals;
const SOURCE = 'RAB contact list of police station OCs (rab.gov.bd/contact-us, Oct 2024)';
const SOURCE_URL = 'https://www.rab.gov.bd/contact-us';
const CHECKED_ON = '2026-11-04';

// Metropolitan police units, by the section headers of the PDF.
const UNITS = {
  'DMP, Dhaka': { id: 'dmp', en: 'Dhaka Metropolitan Police (DMP)', bn: 'ঢাকা মেট্রোপলিটন পুলিশ (ডিএমপি)', district: 'dhaka' },
  'CMP, Chattogram': { id: 'cmp', en: 'Chattogram Metropolitan Police (CMP)', bn: 'চট্টগ্রাম মেট্রোপলিটন পুলিশ (সিএমপি)', district: 'chattogram' },
  'KMP, Khulna': { id: 'kmp', en: 'Khulna Metropolitan Police (KMP)', bn: 'খুলনা মেট্রোপলিটন পুলিশ (কেএমপি)', district: 'khulna' },
  'RMP, Rajshahi': { id: 'rmp', en: 'Rajshahi Metropolitan Police (RMP)', bn: 'রাজশাহী মেট্রোপলিটন পুলিশ (আরএমপি)', district: 'rajshahi' },
  'BMP, Barishal': { id: 'bmp', en: 'Barishal Metropolitan Police (BMP)', bn: 'বরিশাল মেট্রোপলিটন পুলিশ (বিএমপি)', district: 'barishal' },
  'SMP, Sylhet': { id: 'smp', en: 'Sylhet Metropolitan Police (SMP)', bn: 'সিলেট মেট্রোপলিটন পুলিশ (এসএমপি)', district: 'sylhet' },
  'GMP, Gazipur': { id: 'gmp', en: 'Gazipur Metropolitan Police (GMP)', bn: 'গাজীপুর মেট্রোপলিটন পুলিশ (জিএমপি)', district: 'gazipur' },
  'RPMP, Rangpur': { id: 'rpmp', en: 'Rangpur Metropolitan Police (RPMP)', bn: 'রংপুর মেট্রোপলিটন পুলিশ (আরপিএমপি)', district: 'rangpur' },
};

// ---- DMP website: address and e-mail per station ----
// Its phone numbers are not used: the duty-officer cells are 011 numbers
// (Citycell, closed in 2016), the land lines are pre-2018 7-digit Dhaka
// numbers, and the OC cells are the old 01713 series the 01320 list replaced.
function dmpSite() {
  const html = fs.readFileSync(here('source/dmp_find_your_local_police.html'), 'utf8').replace(/<[^>]*>/g, ' ').replace(/[ 	]+/g, ' ');
  const m = html.match(/sessionStorage\.setItem\('h5ab-print-article', ' Find Your Local Police ' \+ "([\s\S]*?)" \+ ' '\);/);
  if (!m) throw new Error('DMP page format changed');
  const text = JSON.parse(`"${m[1]}"`).replace(/&amp;/g, '&');
  const out = {};
  for (const block of text.split(/\n\s*\n\s*(?=[A-Z][^\n]*Police Station\s*\n)/)) {
    const name = (block.match(/^\s*([^\n]*?)\s*Police Station\s*\n/) || [])[1];
    if (!name) continue;
    const address = (block.match(/Address:\s*([^\n]*?)\s*(?:\n|Duty Officer)/) || [])[1] || '';
    const email = (block.match(/E-mail:\s*([\w.@-]+)/) || [])[1] || '';
    out[key(name)] = { address: address.replace(/\s+/g, ' ').trim(), email };
  }
  return out;
}

// Loose spelling key: "Kotoali" = "Kotwali", "Shonargaon" = "Sonargaon".
export function key(s) {
  return String(s).toLowerCase()
    .replace(/\b(oc|model|thana|police|station|ps|upazila)\b/g, ' ')
    .replace(/gonj|gong|gonj/g, 'ganj').replace(/[^a-z]/g, '')
    .replace(/sh/g, 's').replace(/ph/g, 'f').replace(/v/g, 'bh').replace(/w/g, 'o').replace(/z/g, 'j').replace(/y/g, 'i')
    .replace(/[aeiouh]/g, '').replace(/(.)\1+/g, '$1');
}

// Upazila names in Bangla from the DGHS Upazila Health Complexes, per district.
const upazilas = {};
for (const h of hospitals) {
  if (h.kind !== 'Upazila Health Complex') continue;
  const en = h.name.replace(/\s*Upazila Health Complex.*$/i, '').trim();
  const bn = (h.nameBn || '').replace(/\s*উপজেলা স্বাস্থ্য কমপ্লেক্স.*$/, '').replace(/[,\s]+$/, '').trim();
  if (bn) (upazilas[h.districtId] ??= {})[key(en)] = { en, bn };
}

const dmp = dmpSite();
const stations = []; const report = []; const seenIds = new Set();
let section = '';
for (const r of rows) {
  if (r.header) { if (/Division|MP,/.test(r.header)) section = r.header.replace(/\s*Phone Number$/, ''); continue; }
  const raw = r.name.replace(/\s+/g, ' ').trim();
  if (SKIP.has(r.phone)) { report.push(`skipped (not a thana): ${raw} ${r.phone}`); continue; }
  const unit = UNITS[section];
  const block = r.phone.slice(5, 8);
  const districtId = unit ? unit.district : (BLOCK_EXCEPTIONS[r.phone] || DISTRICT_OF_BLOCK[block]);
  if (!districtId) throw new Error(`No district for ${raw} ${r.phone} (${section})`);

  const fixed = NAMES[r.phone];
  const base = raw.replace(/^OC\s*/i, '').replace(/\s*(Model\s+)?(Thana|PS)$/i, '').trim();
  const model = /\bModel\b/i.test(raw);
  let en = fixed?.en; let bn = fixed?.bn;
  if (!en) en = base;
  const up = fixed ? null : upazilas[districtId]?.[key(en)];
  if (up) { report.push(`matched: ${r.phone} ${base} -> ${up.en} / ${up.bn}`); en = EN_FIX[up.en] || up.en; bn = BN_FIX[up.bn] || up.bn; }
  if (!bn) bn = '';
  if (!bn) report.push(`NO BANGLA: ${r.phone} ${districtId} ${raw}`);
  const suffixEn = model ? ' Model Thana' : ' Thana';
  const suffixBn = model ? ' মডেল থানা' : ' থানা';
  const name = /Thana$|Police Station$/.test(en) ? en : en + suffixEn;
  const nameBn = !bn || /থানা$/.test(bn) ? bn : bn + suffixBn;

  let id = `ps-${unit ? unit.id : districtId}-${key(en) || r.phone.slice(-6)}`;
  if (seenIds.has(id)) id += '-' + r.phone.slice(-3);
  seenIds.add(id);
  const site = unit?.id === 'dmp' ? dmp[key(fixed?.dmp || en)] : null;
  if (unit?.id === 'dmp' && !site) report.push(`DMP site has no entry for ${en}`);

  stations.push({
    id, name, nameBn, districtId,
    unit: unit ? unit.en : '', unitBn: unit ? unit.bn : '',
    area: fixed?.area ?? '',
    phone: '+88' + r.phone,
    ...(site?.address ? { address: site.address + (/dhaka\.?$/i.test(site.address) ? '' : ', Dhaka') } : {}),
    ...(site?.email ? { email: site.email } : {}),
    open24h: true,
    source: SOURCE + (site ? '; address and e-mail: DMP website (dmp.gov.bd/find-your-local-police)' : ''),
    sourceUrl: SOURCE_URL,
    checkedOn: CHECKED_ON,
    nameInSource: raw,
  });
}

// Every number once, every district covered.
const byPhone = new Map();
for (const s of stations) { if (byPhone.has(s.phone)) report.push(`DUPLICATE NUMBER ${s.phone}: ${byPhone.get(s.phone)} and ${s.name}`); byPhone.set(s.phone, s.name); }
const districts = new Set(stations.map((s) => s.districtId));
report.unshift(`${stations.length} police stations in ${districts.size} districts; ${stations.filter((s) => s.nameBn).length} with a Bangla name; ${stations.filter((s) => s.address).length} with an address`);

const out = { schemaVersion: 1, updatedAt: CHECKED_ON, source: SOURCE, sourceUrl: SOURCE_URL, policeStations: stations };
fs.writeFileSync(here('police_stations_built.json'), JSON.stringify(out, null, 1));
fs.writeFileSync(here('report.txt'), report.join('\n') + '\n');
if (process.argv.includes('--install')) {
  fs.writeFileSync(here('../../apps/mobile/assets/seed/police_stations.json'), JSON.stringify(out));
  console.log('installed into apps/mobile/assets/seed/police_stations.json');
}
console.log(report.slice(0, 80).join('\n'));
