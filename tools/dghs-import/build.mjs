// Builds app hospital records from the DGHS Facility Registry download.
// In: dghs_list.json, profiles.jsonl   Out: hospitals_built.json + report
import fs from 'node:fs';

const list = JSON.parse(fs.readFileSync('dghs_list.json', 'utf8'));
const profiles = new Map();
if (fs.existsSync('profiles.jsonl')) {
  for (const l of fs.readFileSync('profiles.jsonl', 'utf8').split('\n')) if (l) { const p = JSON.parse(l); profiles.set(p.id, p); }
}

const DISTRICT_IDS = 'barguna barishal bhola jhalokati patuakhali pirojpur bandarban brahmanbaria chandpur chattogram cumilla coxs-bazar feni khagrachhari lakshmipur noakhali rangamati dhaka faridpur gazipur gopalganj kishoreganj madaripur manikganj munshiganj narayanganj narsingdi rajbari shariatpur tangail bagerhat chuadanga jashore jhenaidah khulna kushtia magura meherpur narail satkhira jamalpur mymensingh netrokona sherpur bogura chapainawabganj joypurhat naogaon natore pabna rajshahi sirajganj dinajpur gaibandha kurigram lalmonirhat nilphamari panchagarh rangpur thakurgaon habiganj moulvibazar sunamganj sylhet'.split(' ');
const ALIAS = { jhalokathi: 'jhalokati', khagrachari: 'khagrachhari', maulvibazar: 'moulvibazar', netrakona: 'netrokona', 'cox-s-bazar': 'coxs-bazar',
  chittagong: 'chattogram', comilla: 'cumilla', barisal: 'barishal', jessore: 'jashore', bogra: 'bogura' };
function districtId(name) {
  const k = String(name || '').toLowerCase().replace(/'/g, '').replace(/[^a-z]+/g, '-').replace(/^-|-$/g, '');
  const id = ALIAS[k] || ALIAS[String(name || '').toLowerCase().replace(/[^a-z]+/g, '-')] || k;
  return DISTRICT_IDS.includes(id) ? id : null;
}

// Bangla names of facility types.
const KIND_BN = {
  'Upazila Health Complex': 'উপজেলা স্বাস্থ্য কমপ্লেক্স', 'Medical College Hospital': 'মেডিকেল কলেজ হাসপাতাল',
  'District/General Hospital': 'জেলা/জেনারেল হাসপাতাল', 'General Hospital (Non District Hospital)': 'জেনারেল হাসপাতাল',
  'Postgraduate Institute & Hospital': 'স্নাতকোত্তর ইনস্টিটিউট ও হাসপাতাল', 'Dental College Hospital': 'ডেন্টাল কলেজ হাসপাতাল',
  '50-bed Hospital': '৫০ শয্যার হাসপাতাল', '31-bed Hospital': '৩১ শয্যার হাসপাতাল', '20-bed Hospital': '২০ শয্যার হাসপাতাল',
  '10-bed Hospital': '১০ শয্যার হাসপাতাল', '25-bed Hospital': '২৫ শয্যার হাসপাতাল', '30-bed Hospital': '৩০ শয্যার হাসপাতাল',
  'Specialized Hospital': 'বিশেষায়িত হাসপাতাল', 'Special Purpose Hospital': 'বিশেষ উদ্দেশ্যে হাসপাতাল', 'Specialized Health Center': 'বিশেষায়িত স্বাস্থ্য কেন্দ্র',
  'Infectious Disease Hospital': 'সংক্রামক ব্যাধি হাসপাতাল', 'Chest Disease Hospital': 'বক্ষব্যাধি হাসপাতাল', 'Leprosy Hospital': 'কুষ্ঠ হাসপাতাল',
  'Trauma Center': 'ট্রমা সেন্টার', 'City Corporation / Municipality Hospital': 'সিটি কর্পোরেশন / পৌর হাসপাতাল',
  'Maternal & Child Welfare Centre (MCWC)': 'মা ও শিশু কল্যাণ কেন্দ্র', 'Combined Military Hospital': 'সম্মিলিত সামরিক হাসপাতাল (সিএমএইচ)',
  'Other Hospital': 'অন্যান্য হাসপাতাল', 'Hospital of Alternative Medicine': 'বিকল্প চিকিৎসা হাসপাতাল',
  'Private Hospital / Clinic': 'বেসরকারি হাসপাতাল / ক্লিনিক', 'NGO Hospital/Clinic': 'এনজিও হাসপাতাল / ক্লিনিক', 'Blood Bank': 'ব্লাড ব্যাংক',
};

// Types that run a 24-hour emergency department by government policy.
const EMERGENCY_TYPES = new Set([5, 2, 28, 94, 29, 24, 25, 26, 27, 73, 74, 36]);
const BLOOD_TYPES = new Set([70, 5, 28]); // blood bank; MCH and district hospitals have transfusion units
// Government user-fee chart (MOHFW circular, re-issued 09-04-2023). Only items read without doubt.
const NOTE = 'Govt fixed fee · সরকারি নির্ধারিত ফি';
const T = (name, aliases, priceBdt) => ({ name, aliases, priceBdt, note: NOTE });
const BASIC = [
  T('CBC (TC, DC, ESR, Hb)', ['CBC', 'Complete Blood Count', 'সিবিসি', 'রক্ত পরীক্ষা', 'Hb', 'ESR', 'হিমোগ্লোবিন'], 150),
  T('Blood sugar', ['Sugar', 'Glucose', 'RBS', 'FBS', 'ব্লাড সুগার', 'ডায়াবেটিস', 'সুগার'], 60),
  T('Serum creatinine', ['Creatinine', 'Kidney', 'ক্রিয়েটিনিন', 'কিডনি'], 50),
  T('Blood urea', ['Urea', 'ইউরিয়া'], 50),
  T('Serum bilirubin', ['Bilirubin', 'Jaundice', 'বিলিরুবিন', 'জন্ডিস'], 60),
  T('Lipid profile', ['Cholesterol', 'Lipid', 'লিপিড প্রোফাইল', 'কোলেস্টেরল'], 300),
  T('HbA1c', ['HbA1c', 'Diabetes', 'ডায়াবেটিস'], 300),
  T('Widal test', ['Widal', 'Typhoid', 'টাইফয়েড', 'ভিডাল'], 80),
  T('HBsAg', ['Hepatitis B', 'HBsAg', 'হেপাটাইটিস বি'], 150),
  T('Blood grouping', ['Blood group', 'রক্তের গ্রুপ', 'গ্রুপিং'], 50),
  T('ECG', ['ECG', 'EKG', 'ইসিজি', 'হার্ট'], 80),
  T('X-ray chest (per film)', ['X-ray', 'Xray', 'Chest X-ray', 'এক্সরে', 'বুকের এক্সরে'], 200),
  T('Ultrasound (single organ)', ['Ultrasound', 'USG', 'Ultrasonogram', 'আল্ট্রাসনোগ্রাম', 'আলট্রাসাউন্ড'], 110),
  T('Ultrasound whole abdomen', ['Ultrasound', 'USG', 'Whole abdomen', 'আল্ট্রাসনোগ্রাম', 'পেটের আল্ট্রা'], 220),
];
const BIG = [
  T('CT scan brain (without contrast)', ['CT', 'CT scan', 'সিটি স্ক্যান', 'Brain'], 2000),
  T('MRI (plain)', ['MRI', 'এমআরআই'], 3000),
  T('MRI with contrast', ['MRI', 'এমআরআই', 'Contrast'], 4000),
];
const BASIC_TYPES = new Set([5, 2, 28, 94, 29, 24, 25, 26, 27, 73, 74, 19, 20, 41, 36, 33, 34]);
const BIG_TYPES = new Set([5, 2, 19]);

function phoneNorm(raw) {
  let d = '';
  for (const ch of String(raw || '')) {
    const u = ch.charCodeAt(0);
    if (u >= 48 && u <= 57) d += ch; else if (u >= 0x09E6 && u <= 0x09EF) d += String.fromCharCode(48 + u - 0x09E6); else if (ch === '+' && !d) d += ch;
  }
  if (d.startsWith('+880')) d = '0' + d.slice(4); else if (d.startsWith('880')) d = '0' + d.slice(3);
  // Placeholders typed into the registry: 0000000, 01711111111, 01700000000.
  if (/^000/.test(d) || new Set(d.slice(-8)).size === 1) return null;
  if (/^01[3-9]\d{8}$/.test(d)) return '+88' + d;
  if (/^0\d{6,10}$/.test(d)) return d;          // land line with area code
  if (/^1\d{4}$/.test(d)) return d;             // 5-digit hotlines (10666); local numbers without area code are dropped
  return null;
}
const splitPhones = (s) => String(s || '').split(/[,;/]|\s{2,}/).map(phoneNorm).filter(Boolean);
const clean = (s) => String(s || '').replace(/\s+/g, ' ').trim();
const titleCaseIfShouty = (s) => (s === s.toUpperCase() && /[A-Z]{4}/.test(s) ? s.toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase()) : s);

const out = []; const skipped = []; const seen = new Set();
for (const r of list) {
  const p = profiles.get(r.id) || {};
  const type = r.facility_type_id;
  const dist = districtId(r.district_name) || districtId(r.division_name);
  if (!dist) { skipped.push([r.id, r.name, 'no district']); continue; }
  const name = titleCaseIfShouty(clean(r.name));
  if (!name) { skipped.push([r.id, '', 'no name']); continue; }
  const phones = [...new Set([...splitPhones(r.mobile_1), ...splitPhones(p['Mobile Phone Number 1']), ...splitPhones(p['Mobile Phone Number 2']),
    ...splitPhones(p['Land Phone Number 1']), ...splitPhones(p['Land Phone Number 2']), ...splitPhones(p['Land Phone Number 3']),
    ...splitPhones(p['Official Contact No'])])];
  const gov = r.is_private !== 'Private' && ![43, 44].includes(type);
  const lat = Number(p.Latitude), lng = Number(p.Longitude);
  const inBd = lat > 20.3 && lat < 26.8 && lng > 88 && lng < 92.8;
  const bedsRaw = Number(p['Latest Bed Count']) || (Number(p['Latest Bed Count (Paid)']) || 0) + (Number(p['Latest Bed Count (Free)']) || 0);
  const kind = clean(r.facility_type_name);
  let website = clean(p['Website URL']);
  if (website && !/\./.test(website)) website = '';
  let address = clean(p['Mailing Address']) || clean(p['Village/Street']);
  if (/^n\/?a$|^-+$|@/i.test(address)) address = '';
  const email = clean(r.email_1);
  // Shared government fee chart, expanded by the app (keeps the data small).
  const feeChart = BIG_TYPES.has(type) ? 'govt-full' : BASIC_TYPES.has(type) ? 'govt-basic' : undefined;
  const id = 'dghs-' + r.id;
  if (seen.has(id)) continue; seen.add(id);
  out.push(Object.fromEntries(Object.entries({
    id, name, nameBn: clean(r.name_bn) || undefined, kind, kindBn: KIND_BN[kind] || undefined,
    government: gov || undefined, districtId: dist, area: clean(r.upazila_name) || undefined, address: address || undefined,
    phone: phones[0] || '', otherPhones: phones.length > 1 ? phones.slice(1) : undefined,
    email: /@/.test(email) ? email : undefined, website: website || undefined,
    lat: inBd ? lat : undefined, lng: inBd ? lng : undefined, beds: bedsRaw > 0 && bedsRaw < 5000 ? bedsRaw : undefined,
    emergency: EMERGENCY_TYPES.has(type) || undefined, open24h: EMERGENCY_TYPES.has(type) || undefined,
    bloodBank: BLOOD_TYPES.has(type) || undefined, feeChart,
    source: `DGHS Facility Registry (hris.mohfw.gov.bd), facility ${r.id}` + (feeChart ? '; prices: MOHFW government user-fee chart' : ''),
    published: true,
  }).filter(([, v]) => v !== undefined)));
}
// A map position shared by many facilities is a default, not the real spot.
const spot = (h) => `${h.lat.toFixed(4)},${h.lng.toFixed(4)}`;
const spots = {};
for (const h of out) if (h.lat) spots[spot(h)] = (spots[spot(h)] || 0) + 1;
for (const h of out) if (h.lat && spots[spot(h)] > 3) { delete h.lat; delete h.lng; }
fs.writeFileSync('hospitals_built.json', JSON.stringify(out));
const c = (f) => out.filter(f).length;
console.log('hospitals', out.length, 'skipped', skipped.length, JSON.stringify(skipped.slice(0, 5)));
console.log('with phone', c((h) => h.phone), 'with address', c((h) => h.address), 'with map', c((h) => h.lat), 'government', c((h) => h.government),
  'with fee chart', c((h) => h.feeChart), 'profiles used', profiles.size);
fs.writeFileSync('fee_charts.json', JSON.stringify({ 'govt-basic': BASIC, 'govt-full': [...BASIC, ...BIG] }, null, 1));
console.log('json MB', (Buffer.byteLength(JSON.stringify(out)) / 1048576).toFixed(2));
