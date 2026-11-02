// JORURI BD admin website. Talks only to window.JoruriBackend.
// Every content change raises a version number; phones download the new
// content the next time they are online.
'use strict';

const LOC = {"divisions": [{"id": "barishal", "en": "Barishal", "bn": "বরিশাল"}, {"id": "chattogram", "en": "Chattogram", "bn": "চট্টগ্রাম"}, {"id": "dhaka", "en": "Dhaka", "bn": "ঢাকা"}, {"id": "khulna", "en": "Khulna", "bn": "খুলনা"}, {"id": "mymensingh", "en": "Mymensingh", "bn": "ময়মনসিংহ"}, {"id": "rajshahi", "en": "Rajshahi", "bn": "রাজশাহী"}, {"id": "rangpur", "en": "Rangpur", "bn": "রংপুর"}, {"id": "sylhet", "en": "Sylhet", "bn": "সিলেট"}], "districts": [{"id": "barguna", "divisionId": "barishal", "en": "Barguna", "bn": "বরগুনা"}, {"id": "barishal", "divisionId": "barishal", "en": "Barishal", "bn": "বরিশাল"}, {"id": "bhola", "divisionId": "barishal", "en": "Bhola", "bn": "ভোলা"}, {"id": "jhalokati", "divisionId": "barishal", "en": "Jhalokati", "bn": "ঝালকাঠি"}, {"id": "patuakhali", "divisionId": "barishal", "en": "Patuakhali", "bn": "পটুয়াখালী"}, {"id": "pirojpur", "divisionId": "barishal", "en": "Pirojpur", "bn": "পিরোজপুর"}, {"id": "bandarban", "divisionId": "chattogram", "en": "Bandarban", "bn": "বান্দরবান"}, {"id": "brahmanbaria", "divisionId": "chattogram", "en": "Brahmanbaria", "bn": "ব্রাহ্মণবাড়িয়া"}, {"id": "chandpur", "divisionId": "chattogram", "en": "Chandpur", "bn": "চাঁদপুর"}, {"id": "chattogram", "divisionId": "chattogram", "en": "Chattogram", "bn": "চট্টগ্রাম"}, {"id": "cumilla", "divisionId": "chattogram", "en": "Cumilla", "bn": "কুমিল্লা"}, {"id": "coxs-bazar", "divisionId": "chattogram", "en": "Cox's Bazar", "bn": "কক্সবাজার"}, {"id": "feni", "divisionId": "chattogram", "en": "Feni", "bn": "ফেনী"}, {"id": "khagrachhari", "divisionId": "chattogram", "en": "Khagrachhari", "bn": "খাগড়াছড়ি"}, {"id": "lakshmipur", "divisionId": "chattogram", "en": "Lakshmipur", "bn": "লক্ষ্মীপুর"}, {"id": "noakhali", "divisionId": "chattogram", "en": "Noakhali", "bn": "নোয়াখালী"}, {"id": "rangamati", "divisionId": "chattogram", "en": "Rangamati", "bn": "রাঙ্গামাটি"}, {"id": "dhaka", "divisionId": "dhaka", "en": "Dhaka", "bn": "ঢাকা"}, {"id": "faridpur", "divisionId": "dhaka", "en": "Faridpur", "bn": "ফরিদপুর"}, {"id": "gazipur", "divisionId": "dhaka", "en": "Gazipur", "bn": "গাজীপুর"}, {"id": "gopalganj", "divisionId": "dhaka", "en": "Gopalganj", "bn": "গোপালগঞ্জ"}, {"id": "kishoreganj", "divisionId": "dhaka", "en": "Kishoreganj", "bn": "কিশোরগঞ্জ"}, {"id": "madaripur", "divisionId": "dhaka", "en": "Madaripur", "bn": "মাদারীপুর"}, {"id": "manikganj", "divisionId": "dhaka", "en": "Manikganj", "bn": "মানিকগঞ্জ"}, {"id": "munshiganj", "divisionId": "dhaka", "en": "Munshiganj", "bn": "মুন্সিগঞ্জ"}, {"id": "narayanganj", "divisionId": "dhaka", "en": "Narayanganj", "bn": "নারায়ণগঞ্জ"}, {"id": "narsingdi", "divisionId": "dhaka", "en": "Narsingdi", "bn": "নরসিংদী"}, {"id": "rajbari", "divisionId": "dhaka", "en": "Rajbari", "bn": "রাজবাড়ী"}, {"id": "shariatpur", "divisionId": "dhaka", "en": "Shariatpur", "bn": "শরীয়তপুর"}, {"id": "tangail", "divisionId": "dhaka", "en": "Tangail", "bn": "টাঙ্গাইল"}, {"id": "bagerhat", "divisionId": "khulna", "en": "Bagerhat", "bn": "বাগেরহাট"}, {"id": "chuadanga", "divisionId": "khulna", "en": "Chuadanga", "bn": "চুয়াডাঙ্গা"}, {"id": "jashore", "divisionId": "khulna", "en": "Jashore", "bn": "যশোর"}, {"id": "jhenaidah", "divisionId": "khulna", "en": "Jhenaidah", "bn": "ঝিনাইদহ"}, {"id": "khulna", "divisionId": "khulna", "en": "Khulna", "bn": "খুলনা"}, {"id": "kushtia", "divisionId": "khulna", "en": "Kushtia", "bn": "কুষ্টিয়া"}, {"id": "magura", "divisionId": "khulna", "en": "Magura", "bn": "মাগুরা"}, {"id": "meherpur", "divisionId": "khulna", "en": "Meherpur", "bn": "মেহেরপুর"}, {"id": "narail", "divisionId": "khulna", "en": "Narail", "bn": "নড়াইল"}, {"id": "satkhira", "divisionId": "khulna", "en": "Satkhira", "bn": "সাতক্ষীরা"}, {"id": "jamalpur", "divisionId": "mymensingh", "en": "Jamalpur", "bn": "জামালপুর"}, {"id": "mymensingh", "divisionId": "mymensingh", "en": "Mymensingh", "bn": "ময়মনসিংহ"}, {"id": "netrokona", "divisionId": "mymensingh", "en": "Netrokona", "bn": "নেত্রকোনা"}, {"id": "sherpur", "divisionId": "mymensingh", "en": "Sherpur", "bn": "শেরপুর"}, {"id": "bogura", "divisionId": "rajshahi", "en": "Bogura", "bn": "বগুড়া"}, {"id": "chapainawabganj", "divisionId": "rajshahi", "en": "Chapainawabganj", "bn": "চাঁপাইনবাবগঞ্জ"}, {"id": "joypurhat", "divisionId": "rajshahi", "en": "Joypurhat", "bn": "জয়পুরহাট"}, {"id": "naogaon", "divisionId": "rajshahi", "en": "Naogaon", "bn": "নওগাঁ"}, {"id": "natore", "divisionId": "rajshahi", "en": "Natore", "bn": "নাটোর"}, {"id": "pabna", "divisionId": "rajshahi", "en": "Pabna", "bn": "পাবনা"}, {"id": "rajshahi", "divisionId": "rajshahi", "en": "Rajshahi", "bn": "রাজশাহী"}, {"id": "sirajganj", "divisionId": "rajshahi", "en": "Sirajganj", "bn": "সিরাজগঞ্জ"}, {"id": "dinajpur", "divisionId": "rangpur", "en": "Dinajpur", "bn": "দিনাজপুর"}, {"id": "gaibandha", "divisionId": "rangpur", "en": "Gaibandha", "bn": "গাইবান্ধা"}, {"id": "kurigram", "divisionId": "rangpur", "en": "Kurigram", "bn": "কুড়িগ্রাম"}, {"id": "lalmonirhat", "divisionId": "rangpur", "en": "Lalmonirhat", "bn": "লালমনিরহাট"}, {"id": "nilphamari", "divisionId": "rangpur", "en": "Nilphamari", "bn": "নীলফামারী"}, {"id": "panchagarh", "divisionId": "rangpur", "en": "Panchagarh", "bn": "পঞ্চগড়"}, {"id": "rangpur", "divisionId": "rangpur", "en": "Rangpur", "bn": "রংপুর"}, {"id": "thakurgaon", "divisionId": "rangpur", "en": "Thakurgaon", "bn": "ঠাকুরগাঁও"}, {"id": "habiganj", "divisionId": "sylhet", "en": "Habiganj", "bn": "হবিগঞ্জ"}, {"id": "moulvibazar", "divisionId": "sylhet", "en": "Moulvibazar", "bn": "মৌলভীবাজার"}, {"id": "sunamganj", "divisionId": "sylhet", "en": "Sunamganj", "bn": "সুনামগঞ্জ"}, {"id": "sylhet", "divisionId": "sylhet", "en": "Sylhet", "bn": "সিলেট"}]};
const ALIASES = {"chittagong": "chattogram", "comilla": "cumilla", "barisal": "barishal", "jessore": "jashore", "bogra": "bogura", "chapai nawabganj": "chapainawabganj", "nawabganj": "chapainawabganj", "coxsbazar": "coxs-bazar", "cox bazar": "coxs-bazar", "jhalakathi": "jhalokati", "jhalakati": "jhalokati", "maulvibazar": "moulvibazar", "netrakona": "netrokona", "lakshmipur": "lakshmipur", "laxmipur": "lakshmipur", "khagrachari": "khagrachhari", "rangamati": "rangamati", "jhenaidaha": "jhenaidah", "narshingdi": "narsingdi"};
const GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const NUMBER_CATEGORIES = ['national', 'police', 'fire', 'ambulance', 'health', 'womenChildren', 'government', 'disaster'];
const GUIDE_ICONS = ['heart', 'stroke', 'unconscious', 'choking', 'bleeding', 'burn', 'fracture', 'electric', 'drowning', 'snake',
  'animal', 'poison', 'seizure', 'road', 'fire', 'gas', 'collapse', 'flood', 'cyclone', 'earthquake', 'lightning', 'landslide', 'storm'];
// Collections the phones download (each save raises meta/content.version).
const CONTENT = ['emergency_numbers', 'guides', 'hospitals', 'pharmacies', 'announcements'];
const ICONS = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  announcements: 'M18 11v2h4v-2h-4zm-2 6.61c.96.71 2.21 1.65 3.2 2.39.4-.53.8-1.07 1.2-1.6-.99-.74-2.24-1.68-3.2-2.4-.4.54-.8 1.08-1.2 1.61zM20.4 5.6c-.4-.53-.8-1.07-1.2-1.6-.99.74-2.24 1.68-3.2 2.4.4.53.8 1.07 1.2 1.6.96-.72 2.21-1.65 3.2-2.4zM4 9c-1.1 0-2 .9-2 2v2c0 1.1.9 2 2 2h1v4h2v-4h1l5 3V6L8 9H4zm11.5 3c0-1.33-.58-2.53-1.5-3.35v6.69c.92-.81 1.5-2.01 1.5-3.34z',
  emergency_numbers: 'M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z',
  hospitals: 'M19 3H5c-1.1 0-1.99.9-1.99 2L3 19c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-1 11h-4v4h-4v-4H6v-4h4V6h4v4h4v4z',
  pharmacies: 'M21 5h-2.64l1.14-3.14L17.15 1l-1.46 4H3v2l2 6-2 6v2h18v-2l-2-6 2-6V5zm-5 9h-3v3h-2v-3H8v-2h3V9h2v3h3v2z',
  guides: 'M21 5c-1.11-.35-2.33-.5-3.5-.5-1.95 0-4.05.4-5.5 1.5-1.45-1.1-3.55-1.5-5.5-1.5S2.45 4.9 1 6v14.65c0 .25.25.5.5.5.1 0 .15-.05.25-.05C3.1 20.45 5.05 20 6.5 20c1.95 0 4.05.4 5.5 1.5 1.35-.85 3.8-1.5 5.5-1.5 1.65 0 3.35.3 4.75 1.05.1.05.15.05.25.05.25 0 .5-.25.5-.5V6c-.6-.45-1.25-.75-2-1zm0 13.5c-1.1-.35-2.3-.5-3.5-.5-1.7 0-4.15.65-5.5 1.5V8c1.35-.85 3.8-1.5 5.5-1.5 1.2 0 2.4.15 3.5.5v11.5z',
  donors: 'M12 2c-5.33 4.55-8 8.48-8 11.8 0 4.98 3.8 8.2 8 8.2s8-3.22 8-8.2c0-3.32-2.67-7.25-8-11.8z',
  app: 'M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14zm-1-6h-3V8h-2v5H8l4 4 4-4z',
  admins: 'M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z',
  import: 'M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z',
  audit: 'M13 3c-4.97 0-9 4.03-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9zm-1 5v5l4.28 2.54.72-1.21-3.5-2.08V8H12z',
};
function icon(name) {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('viewBox', '0 0 24 24'); svg.setAttribute('class', 'ico'); svg.setAttribute('aria-hidden', 'true');
  const p = document.createElementNS('http://www.w3.org/2000/svg', 'path'); p.setAttribute('d', ICONS[name] || ''); svg.append(p);
  return svg;
}

/* ---------- small helpers (DOM built with text nodes: no HTML injection) ---------- */
function h(tag, attrs, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'class') el.className = v;
    else if (k === 'value') el.value = v;
    else if (k === 'checked') el.checked = !!v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const kid of kids.flat()) if (kid != null && kid !== false) el.append(kid instanceof Node ? kid : String(kid));
  return el;
}
const $ = (sel) => document.querySelector(sel);
const getPath = (o, path) => path.split('.').reduce((a, k) => (a == null ? undefined : a[k]), o);
function setPath(o, path, v) { const ks = path.split('.'); let cur = o; ks.slice(0, -1).forEach((k) => { cur[k] = cur[k] && typeof cur[k] === 'object' ? cur[k] : {}; cur = cur[k]; }); cur[ks.at(-1)] = v; }
function clean(o) { // Firestore rejects undefined
  if (Array.isArray(o)) return o.map(clean);
  if (o && typeof o === 'object') return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined).map(([k, v]) => [k, clean(v)]));
  return o;
}
const slug = (s) => String(s || '').toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40);
const today = () => new Date().toISOString().slice(0, 10);
function toast(msg, bad) { const t = h('div', { class: 'toast' + (bad ? ' bad' : '') }, msg); document.body.append(t); setTimeout(() => t.remove(), 3500); }

/* ---------- same rules as packages/core (BdPhone, BloodGroup, BdLocations) ---------- */
function cleanDigits(s) { let o = ''; for (const ch of String(s || '')) { const u = ch.charCodeAt(0); if (u >= 48 && u <= 57) o += ch; else if (u >= 0x09E6 && u <= 0x09EF) o += String.fromCharCode(48 + u - 0x09E6); else if (u === 43 && o === '') o += ch; } return o; }
function normMobile(s) { let d = cleanDigits(s); if (d.startsWith('+880')) d = '0' + d.slice(4); else if (d.startsWith('880')) d = '0' + d.slice(3); return /^01[3-9]\d{8}$/.test(d) ? '+88' + d : null; }
function normContact(s) { const m = normMobile(s); if (m) return m; const d = cleanDigits(s); const c = d.replace('+', '').length; return c < 6 || c > 15 ? null : d; }
function parseGroup(s) {
  let v = String(s || '').toUpperCase().replace(/\s+/g, '').replace('\u2212', '-');
  v = v.replace('POSITIVE', '+').replace('NEGATIVE', '-').replace('POS', '+').replace('NEG', '-').replace('VE', '');
  return GROUPS.includes(v) ? v : null;
}
function findDistrict(input) {
  const raw = String(input || '').trim(); const key = raw.toLowerCase().replace(/'/g, '');
  if (!key) return null;
  const id = ALIASES[key] || key.replace(/[^a-z\u0980-\u09FF]+/g, '-');
  return LOC.districts.find((d) => d.id === id || d.bn === raw || d.en.toLowerCase().replace(/'/g, '') === key) || null;
}
const yes = (v) => ['yes', 'y', 'true', '1', 'হ্যাঁ', 'হা'].includes(String(v || '').trim().toLowerCase());
const districtName = (id) => (LOC.districts.find((d) => d.id === id) || {}).en || id || '';

const LEVELS = { info: 'Info (green)', warning: 'Warning (amber)', urgent: 'Urgent (red, cannot be closed)' };
const isExpired = (d) => !!d.endsAt && d.endsAt < today();

/* ---------- what can be edited ---------- */
const bi = (k, label, multi) => ({ k, label, type: multi ? 'bi-multi' : 'bi' });
const SCHEMAS = {
  emergency_numbers: {
    title: 'Emergency numbers', idFrom: (d) => 'bd-' + slug(d.number),
    columns: [['Number', (d) => d.number], ['Name', (d) => d.name?.en], ['Category', (d) => d.category],
      ['Checked', (d) => d.verification?.status === 'verified' ? '✔ verified' : '⚠ not yet'], ['On phones', (d) => d.published ? 'Yes' : 'Hidden']],
    fields: [
      { k: 'number', label: 'Number to dial', required: true },
      { k: 'category', label: 'Category', type: 'select', options: NUMBER_CATEGORIES },
      { k: 'alsoCovers', label: 'Also shown under (comma separated: police, fire, ambulance)', type: 'csv' },
      bi('name', 'Name'), bi('description', 'Description', true),
      { k: 'verification.status', label: 'Checked by a person?', type: 'select', options: ['unverified', 'verified'] },
      { k: 'verification.sourceName', label: 'Source name (e.g. Bangladesh Police website)' },
      { k: 'verification.sourceUrl', label: 'Source link' },
      { k: 'verification.checkedOn', label: 'Checked on', type: 'date' },
      { k: 'verification.note', label: 'Note' },
      { k: 'published', label: 'Show on phones', type: 'checkbox', default: true },
    ],
  },
  hospitals: {
    title: 'Hospitals, tests & prices', idFrom: (d) => slug(d.name) || 'h-' + Date.now(),
    columns: [['Name', (d) => d.name], ['District', (d) => districtName(d.districtId)], ['Phone', (d) => d.phone],
      ['Tests', (d) => (d.tests || []).length], ['On phones', (d) => d.published ? 'Yes' : 'Hidden']],
    fields: [
      { k: 'name', label: 'Hospital name', required: true },
      { k: 'districtId', label: 'District', type: 'district', required: true },
      { k: 'area', label: 'Area' }, { k: 'address', label: 'Address' },
      { k: 'phone', label: 'Phone', type: 'phone', required: true },
      { k: 'emergencyPhone', label: 'Emergency phone', type: 'phone' },
      { k: 'emergency', label: 'Emergency department', type: 'checkbox' },
      { k: 'open24h', label: 'Open 24 hours', type: 'checkbox' },
      { k: 'bloodBank', label: 'Blood bank', type: 'checkbox' },
      { k: 'ambulance', label: 'Ambulance', type: 'checkbox' },
      { k: 'icu', label: 'ICU', type: 'checkbox' },
      { k: 'tests', label: 'Tests and prices: one per line → Test name | other names separated by ; | price in taka | note', type: 'tests' },
      { k: 'pricesCheckedOn', label: 'Prices checked on', type: 'date' },
      { k: 'verified', label: 'Checked by a person', type: 'checkbox' },
      { k: 'published', label: 'Show on phones', type: 'checkbox', default: true },
    ],
  },
  pharmacies: {
    title: 'Pharmacies', idFrom: () => 'p-' + Date.now().toString(36),
    columns: [['Name', (d) => d.name], ['District', (d) => districtName(d.districtId)], ['Area', (d) => d.area],
      ['24 h', (d) => d.open24h ? 'Yes' : ''], ['On phones', (d) => d.published ? 'Yes' : 'Hidden']],
    fields: [
      { k: 'name', label: 'Pharmacy name', required: true },
      { k: 'districtId', label: 'District', type: 'district', required: true },
      { k: 'area', label: 'Area' }, { k: 'address', label: 'Address' },
      { k: 'phone', label: 'Phone', type: 'phone', required: true },
      { k: 'open24h', label: 'Open 24 hours', type: 'checkbox' },
      { k: 'verified', label: 'Checked by a person', type: 'checkbox' },
      { k: 'published', label: 'Show on phones', type: 'checkbox', default: true },
    ],
  },
  guides: {
    title: 'First aid & disaster guides', idFrom: (d) => slug(d.title?.en) || 'g-' + Date.now(),
    columns: [['Title', (d) => d.title?.en], ['Type', (d) => d.kind], ['Review', (d) => d.reviewStatus], ['On phones', (d) => d.published ? 'Yes' : 'Hidden']],
    fields: [
      bi('title', 'Title'),
      { k: 'kind', label: 'Type', type: 'select', options: ['firstAid', 'disaster'] },
      { k: 'icon', label: 'Icon', type: 'select', options: GUIDE_ICONS },
      { k: 'reviewStatus', label: 'Review status (approved = checked by a doctor)', type: 'select', options: ['draft', 'approved', 'pending'] },
      { k: 'doNow', label: 'What to do now (one step per line)', type: 'bi-lines' },
      { k: 'doNot', label: 'What not to do (one per line)', type: 'bi-lines' },
      { k: 'getHelp', label: 'When to get professional help (one per line)', type: 'bi-lines' },
      bi('whoToContact', 'Who to contact', true),
      { k: 'callNumbers', label: 'Call buttons (comma separated, e.g. 999)', type: 'csv' },
      { k: 'sources', label: 'Sources (one link per line)', type: 'lines' },
      { k: 'published', label: 'Show on phones', type: 'checkbox', default: true },
    ],
  },
  announcements: {
    title: 'Announcements', idFrom: () => 'n-' + Date.now().toString(36),
    intro: 'Short notices shown at the top of the app\'s home screen (e.g. flood warning, blood camp, new feature). Phones receive them within seconds when online, and keep them for offline use.',
    columns: [['Title', (d) => d.title?.en || d.title?.bn], ['Level', (d) => LEVELS[d.level] || 'Info'],
      ['Shown', (d) => [d.startsAt && 'from ' + d.startsAt, d.endsAt && 'until ' + d.endsAt].filter(Boolean).join(' ') || 'always'],
      ['On phones', (d) => d.published ? (isExpired(d) ? 'Ended' : 'Yes') : 'Hidden']],
    fields: [
      bi('title', 'Title'),
      bi('body', 'Message', true),
      { k: 'level', label: 'Level', type: 'select', options: Object.entries(LEVELS) },
      { k: 'linkUrl', label: 'Button link (optional): https://…, tel:999 or app:/blood' },
      bi('linkLabel', 'Button text (optional)'),
      { k: 'startsAt', label: 'Show from (optional)', type: 'date' },
      { k: 'endsAt', label: 'Show until (optional, last day shown)', type: 'date' },
      { k: 'published', label: 'Show on phones', type: 'checkbox', default: true },
    ],
  },
  donors: {
    title: 'Blood donors', live: true, idFrom: () => 'a-' + Date.now().toString(36),
    columns: [['Name', (d) => d.name], ['Group', (d) => d.bloodGroup], ['Phone', (d) => d.phone], ['District', (d) => districtName(d.districtId)],
      ['From', (d) => d.source === 'app' ? 'App sign-up' : 'Admin'], ['Status', (d) => [d.available ? 'available' : 'not available', d.verified ? 'checked' : '', d.hidden ? 'HIDDEN' : ''].filter(Boolean).join(', ')]],
    fields: [
      { k: 'name', label: 'Name', required: true },
      { k: 'bloodGroup', label: 'Blood group', type: 'select', options: GROUPS, required: true },
      { k: 'phone', label: 'Mobile number', type: 'mobile', required: true },
      { k: 'districtId', label: 'District', type: 'district', required: true },
      { k: 'area', label: 'Area' },
      { k: 'available', label: 'Available to donate now', type: 'checkbox', default: true },
      { k: 'lastDonation', label: 'Last donation', type: 'date' },
      { k: 'verified', label: 'Checked by an admin (shows a ✔ badge)', type: 'checkbox' },
      { k: 'hidden', label: 'Hide from the app (e.g. after a complaint)', type: 'checkbox' },
      { k: 'shareConsent', label: 'This person agreed to have their number shown (required)', type: 'checkbox', required: true },
    ],
  },
};

/* ---------- state ---------- */
const B = () => window.JoruriBackend;
const state = { user: null, role: null, view: (location.hash || '#dashboard').slice(1), data: {}, search: '' };
const isOwner = () => state.role === 'owner';

async function load(col, force) {
  if (!force && state.data[col]) return state.data[col];
  state.data[col] = await B().list(col);
  return state.data[col];
}
async function afterContentChange(action, col, id, summary) {
  if (CONTENT.includes(col)) await B().bumpContent();
  await B().audit({ action, collection: col, docId: id || '', summary: summary || '' });
}

/* ---------- screens ---------- */
const NAV = [
  ['', 'Overview'], ['dashboard', 'Dashboard'], ['announcements', 'Announcements'], ['app', 'App & updates'],
  ['', 'Content on phones'], ['emergency_numbers', 'Emergency numbers'], ['hospitals', 'Hospitals & tests'],
  ['pharmacies', 'Pharmacies'], ['guides', 'Guides'],
  ['', 'People'], ['donors', 'Blood donors'], ['admins', 'Admins'],
  ['', 'Tools'], ['import', 'Import & backup'], ['audit', 'Activity log'],
];
const VIEWS = new Set(NAV.map(([v]) => v).filter(Boolean));
function shell(content) {
  const close = () => document.body.classList.remove('menu-open');
  return h('div', { class: 'layout' },
    h('aside', { class: 'side' },
      h('div', { class: 'brand' }, h('img', { src: 'logo.png', alt: '' }), h('div', {}, h('b', {}, 'Joruri BD'), h('small', {}, 'Admin panel'))),
      h('nav', {}, NAV.map(([v, label]) => v
        ? h('button', { class: 'navbtn' + (state.view === v ? ' on' : ''), 'data-view': v, onclick: () => { close(); go(v); } }, icon(v), h('span', {}, label))
        : h('div', { class: 'navhead' }, label))),
      h('div', { class: 'who' },
        h('small', {}, state.user?.email || ''),
        h('span', { class: 'badge ' + (isOwner() ? 'owner' : '') }, isOwner() ? 'Owner' : 'Editor'),
        h('button', { class: 'link', onclick: () => B().signOut() }, 'Sign out'))),
    h('div', { class: 'scrim', onclick: close }),
    h('main', { class: 'main' },
      h('div', { class: 'topbar' }, h('button', { class: 'menu', 'aria-label': 'Menu', onclick: () => document.body.classList.add('menu-open') }, '☰'),
        h('b', {}, 'Joruri BD Admin')),
      content));
}
function go(view) {
  state.view = VIEWS.has(view) ? view : 'dashboard'; state.search = '';
  if (location.hash !== '#' + state.view) history.replaceState(null, '', '#' + state.view);
  render();
}
window.addEventListener('hashchange', () => { const v = location.hash.slice(1); if (v !== state.view && VIEWS.has(v)) go(v); });

async function render() {
  const root = $('#app');
  if (!B()) { root.replaceChildren(h('p', { class: 'center' }, 'Loading…')); return; }
  if (!B().configured) { root.replaceChildren(setupScreen()); return; }
  if (!state.user) { root.replaceChildren(loginScreen()); return; }
  if (state.adminError) { root.replaceChildren(accessCheckFailedScreen()); return; }
  if (!state.role) { root.replaceChildren(notAdminScreen()); return; }
  if (!VIEWS.has(state.view)) state.view = 'dashboard';
  const view = state.view;
  root.replaceChildren(shell(h('div', { class: 'loading' }, h('span', { class: 'spinner' }), 'Loading…')));
  try {
    const content = view === 'dashboard' ? await dashboard()
      : view === 'import' ? importScreen()
        : view === 'audit' ? await auditScreen()
          : view === 'app' ? await appScreen()
            : view === 'admins' ? await adminsScreen()
              : await listScreen(view);
    if (state.view !== view) return; // the person moved on while this loaded
    root.replaceChildren(shell(content));
  } catch (e) {
    console.error(e);
    root.replaceChildren(shell(h('div', { class: 'card bad' }, 'Could not load: ' + (e.message || e))));
  }
}

function setupScreen() {
  return h('div', { class: 'login card' }, h('h1', {}, 'Almost ready'),
    h('p', {}, 'Paste your Firebase web settings into admin/firebase-config.js, then deploy again. See SETUP_ONLINE.md, step 7.'));
}
function loginScreen() {
  const msg = h('p', { class: 'err', id: 'loginError' });
  const google = async () => {
    msg.textContent = '';
    try { await B().signInWithGoogle(); }
    catch (err) {
      console.error(err);
      if (err && (err.code === 'auth/popup-closed-by-user' || err.code === 'auth/cancelled-popup-request')) return;
      msg.textContent = err && err.code === 'auth/unauthorized-domain'
        ? 'This website address is not in Authentication → Settings → Authorized domains.'
        : 'Google sign-in did not work. Check that the Google provider is enabled (SETUP_ONLINE.md).';
    }
  };
  const email = h('input', { type: 'email', id: 'email', placeholder: 'admin@example.com', autocomplete: 'username' });
  const pw = h('input', { type: 'password', id: 'password', autocomplete: 'current-password' });
  const submit = async (ev) => {
    ev.preventDefault(); msg.textContent = '';
    try { await B().signIn(email.value.trim(), pw.value); } catch (err) { msg.textContent = 'Wrong email or password.'; console.error(err); }
  };
  return h('div', { class: 'login card' },
    h('img', { src: 'logo.png', alt: 'Joruri', class: 'logo' }), h('h1', {}, 'Joruri BD admin'),
    h('button', { class: 'primary', id: 'googleLogin', onclick: google }, 'Sign in with Google'),
    h('p', { class: 'hint center' }, 'Only Google accounts on the admin list can open the panel.'),
    msg,
    h('details', {}, h('summary', {}, 'Use email and password instead'),
      h('form', { onsubmit: submit, class: 'stack' },
        h('label', {}, 'Email', email), h('label', {}, 'Password', pw),
        h('button', { type: 'submit', id: 'login' }, 'Sign in with email'))));
}
function uidBox() {
  return h('div', { class: 'card' },
    h('p', {}, 'Signed in as ', h('b', {}, state.user.email || '(no email)')),
    h('p', {}, 'Your User UID:'), h('p', {}, h('code', { id: 'uid' }, state.user.uid)),
    h('button', { onclick: () => navigator.clipboard && navigator.clipboard.writeText(state.user.uid).then(() => toast('UID copied')) }, 'Copy UID'));
}
function notAdminScreen() {
  return h('div', { class: 'login card' }, h('h1', {}, 'Not an admin'),
    h('p', {}, 'This Google account is not on the admin list. Ask an owner to add your Gmail address on the Admins page of this panel, then sign in again.'),
    uidBox(), h('button', { onclick: () => B().signOut() }, 'Sign out'));
}
function accessCheckFailedScreen() {
  const locked = /permission/i.test(state.adminError || '');
  return h('div', { class: 'login card' }, h('h1', {}, locked ? 'Database is locked' : 'Could not check admin access'),
    locked
      ? h('p', {}, 'The database refused to check the admin list. Make sure the rules in firebase/firestore.rules are deployed (firebase deploy --only firestore:rules).')
      : h('p', {}, 'The admin list could not be read (' + state.adminError + '). Check the internet connection and try again.'),
    uidBox(),
    h('div', { class: 'row' }, h('button', { onclick: () => location.reload() }, 'Try again'), h('button', { onclick: () => B().signOut() }, 'Sign out')));
}

async function dashboard() {
  const [meta, appMeta, ...lists] = await Promise.all([B().getMeta('content'), B().getMeta('app'),
    ...['emergency_numbers', 'hospitals', 'pharmacies', 'guides', 'donors', 'announcements'].map((c) => load(c, true))]);
  const [numbers, hospitals, pharmacies, guides, donors, notices] = lists;
  const stat = (label, n, view, sub) => h('button', { class: 'stat', onclick: () => go(view) }, icon(view), h('b', {}, n), h('span', {}, label), sub ? h('small', {}, sub) : null);
  const unverified = numbers.filter((n) => n.verification?.status !== 'verified').length;
  const empty = guides.filter((g) => !(g.doNow?.en || []).length && !(g.doNow?.bn || []).length).length;
  const liveNotices = notices.filter((n) => n.published && !isExpired(n)).length;
  const todo = [
    hospitals.length === 0 && ['hospitals', 'No hospitals yet: the Hospitals screen in the app is empty. Add them one by one or import the spreadsheet.'],
    pharmacies.length === 0 && ['pharmacies', 'No pharmacies yet: the Pharmacy screen in the app is empty.'],
    donors.length === 0 && ['donors', 'No blood donors yet. Add donors who agreed to share their number, or import the spreadsheet.'],
    empty && ['guides', `${empty} guide(s) have no steps yet; the app shows them as "being written".`],
    unverified && ['emergency_numbers', `${unverified} emergency number(s) are not marked as checked; the app shows a "not yet verified" label.`],
    !appMeta.latestVersionCode && ['app', 'No app release is published yet, so phones are not told about updates.'],
  ].filter(Boolean);
  return h('div', {},
    h('div', { class: 'head' }, h('h1', {}, 'Dashboard'),
      h('button', { class: 'primary', onclick: pushNow, title: 'Makes every phone re-download the content now' }, '⟳ Send content to phones now')),
    h('div', { class: 'stats' },
      stat('Announcements', liveNotices, 'announcements', `${notices.length} total`),
      stat('Emergency numbers', numbers.length, 'emergency_numbers', unverified ? `${unverified} not checked yet` : 'all checked'),
      stat('Hospitals', hospitals.length, 'hospitals', `${hospitals.reduce((a, x) => a + (x.tests || []).length, 0)} test prices`),
      stat('Pharmacies', pharmacies.length, 'pharmacies', `${pharmacies.filter((p) => p.open24h).length} open 24 h`),
      stat('Guides', guides.length, 'guides', `${guides.filter((g) => g.reviewStatus === 'approved').length} doctor-approved`),
      stat('Blood donors', donors.length, 'donors', `${donors.filter((d) => d.source === 'app').length} signed up in the app`),
      stat('App version', appMeta.latestVersionName || '—', 'app', appMeta.latestVersionCode ? `build ${appMeta.latestVersionCode}` : 'not published')),
    todo.length ? h('div', { class: 'card' }, h('h3', {}, 'To do'),
      h('ul', { class: 'todo' }, todo.map(([v, t]) => h('li', {}, h('button', { class: 'link', onclick: () => go(v) }, t))))) : null,
    h('div', { class: 'card' }, h('h3', {}, 'How phones get your changes'),
      h('p', {}, `Every save raises the content version (now ${meta.version || 0}${meta.updatedAt ? ', last change ' + fmtTime(meta.updatedAt) : ''}). Phones that are online receive the change within seconds; phones that are offline get it the next time they connect. Everything is kept on the phone, so it keeps working without internet.`),
      h('p', { class: 'hint' }, 'Blood donors are not copied to phones: signed-in users see the live list directly.')));
}
const fmtTime = (iso) => { try { return new Date(iso).toLocaleString(); } catch { return iso; } };
async function pushNow() {
  try {
    await B().bumpContent();
    await B().audit({ action: 'push', collection: 'meta', docId: 'content', summary: 'Sent content to phones' });
    toast('Done. Online phones will refresh within seconds.'); render();
  } catch (err) { console.error(err); toast('Could not send: ' + (err.message || err), true); }
}

async function listScreen(col) {
  const schema = SCHEMAS[col];
  const items = await load(col);
  // Sorted once by the first column (was computed but never used before).
  const sorted = [...items].sort((a, b) => String(schema.columns[0][1](a) || '').localeCompare(String(schema.columns[0][1](b) || '')));
  const search = h('input', { type: 'search', placeholder: 'Search…', value: state.search, id: 'search' });
  search.addEventListener('input', () => { state.search = search.value; renderList(); });
  const tableWrap = h('div', { class: 'tablewrap' });
  function renderList() {
    const qq = state.search.toLowerCase();
    const shown = sorted.filter((d) => !qq || JSON.stringify(d).toLowerCase().includes(qq));
    tableWrap.replaceChildren(h('table', {},
      h('thead', {}, h('tr', {}, schema.columns.map(([t]) => h('th', {}, t)), h('th', {}))),
      h('tbody', {}, shown.length ? shown.map((d) => h('tr', { class: d.hidden || d.published === false ? 'muted' : '' },
        schema.columns.map(([, f]) => h('td', {}, f(d) ?? '')),
        h('td', { class: 'actions' }, h('button', { onclick: () => openForm(col, d) }, 'Edit'),
          h('button', { class: 'danger', onclick: () => remove(col, d) }, 'Delete'))))
        : h('tr', {}, h('td', { colspan: schema.columns.length + 1, class: 'center' }, 'Nothing here yet.')))));
  }
  renderList();
  return h('div', {},
    h('div', { class: 'head' }, h('h1', {}, schema.title, ' ', h('small', {}, `(${items.length})`)),
      search, h('button', { class: 'primary', id: 'add', onclick: () => openForm(col, null) }, '+ Add')),
    schema.intro ? h('p', { class: 'hint' }, schema.intro) : null,
    schema.live ? h('p', { class: 'hint' }, 'Donor changes show in the app immediately for signed-in users. Donors who signed up in the app manage their own details; you can mark them checked or hide them.') : null,
    tableWrap);
}

/* ---------- edit form ---------- */
function field(f, value) {
  const name = f.k;
  const wrap = (input) => h('label', { class: 'field' + (f.type === 'checkbox' ? ' check' : '') }, f.type === 'checkbox' ? [input, f.label] : [f.label + (f.required ? ' *' : ''), input]);
  switch (f.type) {
    case 'checkbox': return wrap(h('input', { type: 'checkbox', name, checked: value ?? f.default ?? false }));
    case 'select': return wrap(h('select', { name }, f.options.map((o) => {
      const [v, label] = Array.isArray(o) ? o : [o, o];
      return h('option', { value: v, selected: v === value ? 'selected' : null }, label);
    })));
    case 'number': return wrap(h('input', { type: 'number', name, min: f.min ?? 0, step: 1, value: value ?? '' }));
    case 'district': {
      const sel = h('select', { name }, h('option', { value: '' }, '— choose —'),
        LOC.divisions.map((dv) => h('optgroup', { label: dv.en }, LOC.districts.filter((d) => d.divisionId === dv.id).map((d) => h('option', { value: d.id, selected: d.id === value ? 'selected' : null }, `${d.en} · ${d.bn}`)))));
      return wrap(sel);
    }
    case 'date': return wrap(h('input', { type: 'date', name, value: value || '' }));
    case 'csv': return wrap(h('input', { name, value: (value || []).join(', ') }));
    case 'lines': return wrap(h('textarea', { name, rows: 3 }, (value || []).join('\n')));
    case 'tests': return wrap(h('textarea', { name, rows: 8, class: 'mono' },
      (value || []).map((t) => [t.name, (t.aliases || []).join('; '), t.priceBdt ?? '', t.note || ''].join(' | ').replace(/( \| )+$/, '')).join('\n')));
    case 'bi': case 'bi-multi': {
      const tag = f.type === 'bi' ? 'input' : 'textarea';
      const mk = (lang) => h(tag, { name: `${name}.${lang}`, value: tag === 'input' ? (value?.[lang] || '') : null, rows: 3, lang }, tag === 'textarea' ? (value?.[lang] || '') : null);
      return h('div', { class: 'field bi' }, h('span', {}, f.label), h('div', { class: 'two' }, h('label', {}, 'English', mk('en')), h('label', {}, 'বাংলা', mk('bn'))));
    }
    case 'bi-lines': {
      const mk = (lang) => h('textarea', { name: `${name}.${lang}`, rows: 5, lang }, (value?.[lang] || []).join('\n'));
      return h('div', { class: 'field bi' }, h('span', {}, f.label), h('div', { class: 'two' }, h('label', {}, 'English', mk('en')), h('label', {}, 'বাংলা', mk('bn'))));
    }
    default: return wrap(h('input', { name, value: value ?? '' }));
  }
}

function readForm(form, schema) {
  const out = {}; const problems = [];
  const val = (n) => form.elements.namedItem(n);
  for (const f of schema.fields) {
    const lines = (s) => s.split('\n').map((x) => x.trim()).filter(Boolean);
    let v;
    switch (f.type) {
      case 'checkbox': v = val(f.k).checked; break;
      case 'number': { const raw = val(f.k).value.trim(); v = raw === '' ? undefined : Number(raw); if (raw && !Number.isInteger(v)) problems.push(`${f.label}: must be a whole number`); break; }
      case 'csv': v = val(f.k).value.split(',').map((x) => x.trim()).filter(Boolean); break;
      case 'lines': v = lines(val(f.k).value); break;
      case 'bi': case 'bi-multi': v = { en: val(`${f.k}.en`).value.trim(), bn: val(`${f.k}.bn`).value.trim() }; break;
      case 'bi-lines': v = { en: lines(val(`${f.k}.en`).value), bn: lines(val(`${f.k}.bn`).value) }; break;
      case 'tests': v = lines(val(f.k).value).map((line, i) => {
        const [name, aliases = '', price = '', note = ''] = line.split('|').map((x) => x.trim());
        const p = cleanDigits(price).replace('+', '');
        if (!name) problems.push(`Tests line ${i + 1} has no test name`);
        return clean({ name, aliases: aliases.split(';').map((a) => a.trim()).filter(Boolean), priceBdt: p ? Number(p) : undefined, note: note || undefined });
      }); break;
      case 'phone': { const raw = val(f.k).value.trim(); v = raw ? normContact(raw) : undefined; if (raw && !v) problems.push(`${f.label}: "${raw}" is not a valid number`); break; }
      case 'mobile': { const raw = val(f.k).value.trim(); v = normMobile(raw) || undefined; if (raw && !v) problems.push(`${f.label}: "${raw}" is not a valid Bangladeshi mobile`); break; }
      default: v = val(f.k).value.trim() || undefined;
    }
    const empty = v === undefined || v === '' || v === false || (typeof v === 'object' && !Array.isArray(v) && !Object.values(v).some((x) => (Array.isArray(x) ? x.length : x)));
    if (f.required && empty) problems.push(`${f.label.replace(' *', '')} is required`);
    setPath(out, f.k, v);
  }
  return { data: clean(out), problems };
}

function openForm(col, existing) {
  const schema = SCHEMAS[col];
  const form = h('form', { class: 'editor', id: 'editor' });
  const errs = h('div', { class: 'err' });
  form.append(h('h2', {}, existing ? 'Edit' : 'Add', ' · ', schema.title),
    existing?.source === 'app' ? h('p', { class: 'hint' }, 'Signed up in the app: name, phone and blood group come from the person. You can mark them checked or hide them.') : null,
    ...schema.fields.map((f) => field(f, existing ? getPath(existing, f.k) : f.default)),
    errs,
    h('div', { class: 'row' }, h('button', { type: 'button', onclick: () => dialog.remove() }, 'Cancel'), h('button', { class: 'primary', type: 'submit', id: 'save' }, 'Save')));
  const dialog = h('div', { class: 'overlay', onmousedown: (e) => { if (e.target === dialog) dialog.remove(); } }, form);
  form.addEventListener('keydown', (e) => { if (e.key === 'Escape') dialog.remove(); });
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const { data, problems } = readForm(form, schema);
    if (problems.length) { errs.replaceChildren(...problems.map((p) => h('div', {}, '• ' + p))); return; }
    let id = existing?.id || schema.idFrom(data);
    // A new item must never overwrite another one that happens to get the
    // same ID (e.g. two hospitals with the same name in different districts).
    if (!existing && (state.data[col] || []).some((x) => x.id === id)) id = `${id}-${Date.now().toString(36).slice(-5)}`;
    const doc = clean({ ...(existing || {}), ...data, id, updatedAt: new Date().toISOString() });
    if (col === 'donors' && !existing) doc.source = 'admin';
    if (col === 'hospitals') doc.demo = false;
    const btn = form.querySelector('#save'); btn.disabled = true; btn.textContent = 'Saving…';
    try {
      await B().set(col, id, doc);
      await afterContentChange(existing ? 'edit' : 'add', col, id, doc.name?.en || doc.title?.en || doc.name || doc.number || '');
      const list = state.data[col] || []; const i = list.findIndex((x) => x.id === id);
      if (i >= 0) list[i] = doc; else list.push(doc);
      dialog.remove(); toast('Saved. Phones will update automatically.'); render();
    } catch (err) { console.error(err); errs.textContent = 'Could not save: ' + (err.message || err); btn.disabled = false; btn.textContent = 'Save'; }
  });
  document.body.append(dialog);
  form.querySelector('input,select,textarea')?.focus();
}

async function remove(col, d) {
  const label = d.name?.en || d.title?.en || d.name || d.number || d.id;
  if (!confirm(`Delete "${label}"? Phones will remove it on their next update.`)) return;
  try {
    await B().del(col, d.id);
    await afterContentChange('delete', col, d.id, String(label));
    state.data[col] = (state.data[col] || []).filter((x) => x.id !== d.id);
    toast('Deleted.'); render();
  } catch (err) { console.error(err); toast('Could not delete: ' + (err.message || err), true); }
}

/* ---------- import ---------- */
function parseCsv(text) {
  if (text.charCodeAt(0) === 0xFEFF) text = text.slice(1);
  const rows = []; let row = []; let f = ''; let q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"') { if (text[i + 1] === '"') { f += '"'; i++; } else q = false; } else f += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; row.push(f); f = ''; rows.push(row); row = []; }
    else f += c;
  }
  if (f || row.length) { row.push(f); rows.push(row); }
  const header = (rows.shift() || []).map((x) => x.trim().toLowerCase().replace(/ /g, '_'));
  return rows.filter((r) => r.some((x) => x.trim())).map((r) => Object.fromEntries(header.map((k, i) => [k, (r[i] || '').trim()])));
}
const readFile = (file) => new Promise((ok, fail) => { const r = new FileReader(); r.onload = () => ok(r.result); r.onerror = fail; r.readAsText(file, 'utf-8'); });

function fromDonorRows(rows) {
  const items = []; const problems = []; const seen = new Set();
  rows.forEach((r, i) => {
    const line = i + 2; const g = parseGroup(r.blood_group); const p = normMobile(r.phone); const d = findDistrict(r.district);
    const why = [!r.name && 'no name', !g && `blood group "${r.blood_group}"`, !p && `phone "${r.phone}"`, !d && `district "${r.district}"`, !yes(r.consent) && 'consent is not "yes"'].filter(Boolean);
    if (why.length) return problems.push(`Row ${line}: ${why.join('; ')}`);
    if (seen.has(p)) return problems.push(`Row ${line}: same phone as an earlier row`);
    seen.add(p);
    items.push(clean({ id: 'a-' + p.slice(1), name: r.name, bloodGroup: g, phone: p, districtId: d.id, area: r.area || '', available: !r.available || yes(r.available),
      lastDonation: /^\d{4}-\d{2}-\d{2}$/.test(r.last_donation || '') ? r.last_donation : undefined, verified: yes(r.verified), hidden: false, shareConsent: true, source: 'admin' }));
  });
  return { items, problems };
}
function fromPlaceRows(rows, kind) {
  const items = []; const problems = [];
  rows.forEach((r, i) => {
    const line = i + 2; const d = findDistrict(r.district); const p = normContact(r.phone);
    const why = [!r.name && 'no name', !d && `district "${r.district}"`, !p && `phone "${r.phone}"`, kind === 'hospitals' && !r.id && 'no id'].filter(Boolean);
    if (why.length) return problems.push(`Row ${line}: ${why.join('; ')}`);
    const base = { name: r.name, districtId: d.id, area: r.area || '', address: r.address || '', phone: p, open24h: yes(r.open_24h), verified: yes(r.verified), published: true };
    items.push(clean(kind === 'hospitals'
      ? { ...base, id: slug(r.id), emergencyPhone: normContact(r.emergency_phone) || undefined, emergency: yes(r.emergency), bloodBank: yes(r.blood_bank),
        ambulance: yes(r.ambulance), icu: yes(r.icu), pricesCheckedOn: r.prices_checked_on || undefined, tests: [], demo: false }
      : { ...base, id: 'p-' + slug(r.name + '-' + d.id) }));
  });
  return { items, problems };
}
function attachTests(hospitals, rows, problems) {
  const byId = Object.fromEntries(hospitals.map((x) => [x.id, x]));
  rows.forEach((r, i) => {
    const h0 = byId[slug(r.hospital_id)];
    if (!h0) return problems.push(`Tests row ${i + 2}: hospital_id "${r.hospital_id}" is not in the hospitals file`);
    if (!r.test) return problems.push(`Tests row ${i + 2}: no test name`);
    const p = cleanDigits(r.price).replace('+', '');
    h0.tests.push(clean({ name: r.test, aliases: (r.aliases || '').split('|').map((a) => a.trim()).filter(Boolean), priceBdt: p ? Number(p) : undefined, note: r.note || undefined }));
  });
}
function fromSeedJson(json) {
  const out = [];
  const add = (col, list, extra) => list && out.push({ col, items: list.map((x) => clean({ ...x, ...extra, demo: undefined })) });
  add('emergency_numbers', json.numbers, { published: true });
  add('guides', json.guides, { published: true });
  add('hospitals', json.hospitals, { published: true });
  add('pharmacies', json.pharmacies, { published: true });
  add('donors', json.donors && json.donors.filter((d) => d.shareConsent), { source: 'admin', hidden: false });
  return out;
}

function importScreen() {
  const preview = h('div', { id: 'preview' });
  let pending = []; // [{col, items}]
  const show = (batches, problems) => {
    pending = batches.filter((b) => b.items.length);
    preview.replaceChildren(
      pending.length ? h('div', { class: 'card ok' }, h('b', {}, 'Ready to import:'), h('ul', {}, pending.map((b) => h('li', {}, `${b.items.length} → ${SCHEMAS[b.col].title}`))),
        h('p', { class: 'hint' }, 'Items with the same ID are replaced; everything else stays.'),
        h('button', { class: 'primary', id: 'doImport', onclick: run }, 'Import now')) : h('p', {}, 'Nothing to import.'),
      problems.length ? h('div', { class: 'card bad' }, h('b', {}, `${problems.length} row(s) skipped — fix them in the spreadsheet and choose the file again:`), h('ul', {}, problems.slice(0, 200).map((p) => h('li', {}, p)))) : null);
  };
  async function run() {
    const btn = $('#doImport'); btn.disabled = true; btn.textContent = 'Importing…';
    try {
      for (const b of pending) {
        await B().batchSet(b.col, b.items.map((x) => ({ ...x, updatedAt: new Date().toISOString() })));
        await B().audit({ action: 'import', collection: b.col, docId: '', summary: `${b.items.length} items` });
        delete state.data[b.col];
      }
      if (pending.some((b) => CONTENT.includes(b.col))) await B().bumpContent();
      toast('Imported. Phones will update automatically.'); go('dashboard');
    } catch (err) { console.error(err); toast('Import failed: ' + (err.message || err), true); btn.disabled = false; btn.textContent = 'Import now'; }
  }
  const picker = (id, label, accept, multiple, handler) => {
    const input = h('input', { type: 'file', id, accept, multiple: multiple || null });
    input.addEventListener('change', async () => { try { await handler([...input.files]); } catch (e) { console.error(e); toast('Could not read the file: ' + e.message, true); } });
    return h('label', { class: 'field' }, label, input);
  };
  async function backup() {
    const out = { exportedAt: new Date().toISOString(), meta: { content: await B().getMeta('content'), app: await B().getMeta('app') } };
    for (const col of [...CONTENT, 'donors']) out[col] = await B().list(col);
    const blob = new Blob([JSON.stringify(out, null, 1)], { type: 'application/json' });
    const a = h('a', { href: URL.createObjectURL(blob), download: `joruri-backup-${today()}.json` });
    document.body.append(a); a.click(); a.remove();
    toast('Backup downloaded.');
  }
  return h('div', {},
    h('h1', {}, 'Import & backup'),
    h('div', { class: 'card' }, h('h3', {}, 'Backup'),
      h('p', {}, 'Download everything (content, announcements, donors, app settings) as one JSON file. Keep a copy before big changes.'),
      h('button', { class: 'primary', onclick: () => backup().catch((e) => toast('Backup failed: ' + e.message, true)) }, '⭳ Download backup')),
    h('div', { class: 'card' }, h('h3', {}, '1 · Start from the app\'s built-in data'),
      h('p', {}, 'Choose the files from apps/mobile/assets/seed/: emergency_numbers.json, guides.json, and (optional) hospitals.json, pharmacies.json, donors.json. Do not import the *_demo files.'),
      picker('seedFiles', 'Seed JSON files', '.json', true, async (files) => {
        const batches = []; const problems = [];
        for (const f of files) {
          if (/_demo/.test(f.name)) { problems.push(`${f.name}: demo data skipped`); continue; }
          try { batches.push(...fromSeedJson(JSON.parse(await readFile(f)))); } catch (e) { problems.push(`${f.name}: not valid JSON`); }
        }
        show(batches, problems);
      })),
    h('div', { class: 'card' }, h('h3', {}, '2 · Spreadsheets (saved as CSV UTF-8)'),
      h('p', {}, 'Same columns as the templates in apps/mobile/tool/.'),
      picker('donorCsv', 'Blood donors (donors_template.csv)', '.csv', false, async ([f]) => { const r = fromDonorRows(parseCsv(await readFile(f))); show([{ col: 'donors', items: r.items }], r.problems); }),
      picker('pharmacyCsv', 'Pharmacies (pharmacies_template.csv)', '.csv', false, async ([f]) => { const r = fromPlaceRows(parseCsv(await readFile(f)), 'pharmacies'); show([{ col: 'pharmacies', items: r.items }], r.problems); }),
      picker('hospitalCsv', 'Hospitals + tests: choose BOTH files together (hospitals_template.csv and hospital_tests_template.csv)', '.csv', true, async (files) => {
        const hf = files.find((f) => !/test/i.test(f.name)); const tf = files.find((f) => /test/i.test(f.name));
        if (!hf) return show([], ['Choose the hospitals file (and the tests file) together']);
        const r = fromPlaceRows(parseCsv(await readFile(hf)), 'hospitals');
        if (tf) attachTests(r.items, parseCsv(await readFile(tf)), r.problems);
        show([{ col: 'hospitals', items: r.items }], r.problems);
      })),
    preview);
}

async function auditScreen() {
  const entries = await B().listAudit();
  return h('div', {}, h('h1', {}, 'Activity log'), h('p', { class: 'hint' }, 'Every change made on this website. It cannot be edited or deleted.'),
    h('div', { class: 'tablewrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['When', 'Who', 'What', 'Where', 'Item'].map((x) => h('th', {}, x)))),
      h('tbody', {}, entries.map((e) => h('tr', {}, h('td', {}, (e.at || '').replace('T', ' ').slice(0, 16)), h('td', {}, e.by), h('td', {}, e.action),
        h('td', {}, SCHEMAS[e.collection]?.title || e.collection), h('td', {}, e.summary || e.docId)))))));
}

/* ---------- app & updates (meta/app) ---------- */
const RELEASES_REPO = 'Ashfaq1306/joruri-bd-releases';
const RELEASES_DL = `https://github.com/${RELEASES_REPO}/releases/latest/download`;
const APP_FIELDS = [
  { k: 'latestVersionName', label: 'Latest version name (e.g. 1.2.0)' },
  { k: 'latestVersionCode', label: 'Latest build number (the number after + in pubspec.yaml, e.g. 12)', type: 'number' },
  { k: 'minVersionCode', label: 'Oldest build still allowed (phones below this see an urgent "update now" message; 0 = none)', type: 'number' },
  { k: 'apkUrl', label: 'Download link for most phones (64-bit)' },
  { k: 'apkUrlArm32', label: 'Download link for older phones (32-bit)' },
  bi('notes', 'What is new (shown in the update message)', true),
  { k: 'showDraftGuides', label: 'Show first-aid guides that a doctor has not approved yet (with a warning)', type: 'checkbox', default: true },
  { k: 'showUnverifiedContent', label: 'Show emergency numbers that are not marked as checked (with a label)', type: 'checkbox', default: true },
];
async function appScreen() {
  const current = await B().getMeta('app');
  const form = h('form', { class: 'card stack' });
  const errs = h('div', { class: 'err' });
  const rel = h('div', { class: 'card ok' }, 'Checking the latest published release…');
  let latest = null;
  fetch(`https://api.github.com/repos/${RELEASES_REPO}/releases/latest`, { cache: 'no-store' }).then((r) => (r.ok ? r.json() : null)).then((r) => {
    if (!r) { rel.replaceChildren('No release published yet (run the release script).'); return; }
    const m = /<!-- joruri (\{.*\}) -->/.exec(r.body || '');
    const info = m ? JSON.parse(m[1]) : {};
    const code = info.versionCode || Number((/build(\d+)$/.exec(r.tag_name) || [])[1]) || 0;
    latest = { versionName: info.versionName || r.tag_name, versionCode: code, notes: info.notes || {} };
    const live = (current.latestVersionCode || 0) >= code;
    rel.className = 'card ' + (live ? 'ok' : 'bad');
    rel.replaceChildren(
      h('b', {}, `Latest published release: ${latest.versionName} (build ${code}) · ${fmtTime(r.published_at)}`),
      h('p', {}, live ? 'Phones already know about this version.' : 'Phones have NOT been told about this version yet.'),
      live ? null : h('button', { type: 'button', class: 'primary', onclick: fill }, 'Use latest release'),
      ' ', h('a', { href: r.html_url, target: '_blank', rel: 'noopener' }, 'See on GitHub'));
  }).catch(() => rel.replaceChildren('Could not reach GitHub to check releases.'));
  function fill() {
    const set = (k, v) => { const el = form.elements.namedItem(k); if (el && v != null) el.value = v; };
    set('latestVersionName', latest.versionName); set('latestVersionCode', latest.versionCode);
    set('apkUrl', `${RELEASES_DL}/joruri-bd.apk`); set('apkUrlArm32', `${RELEASES_DL}/joruri-bd-arm32.apk`);
    set('notes.en', latest.notes.en || ''); set('notes.bn', latest.notes.bn || '');
    toast('Filled in. Press Save to tell every phone.');
    form.querySelector('#saveApp').focus();
  }
  form.append(...APP_FIELDS.map((f) => field(f, getPath(current, f.k) ?? f.default)), errs,
    h('div', { class: 'row' }, h('button', { class: 'primary', type: 'submit', id: 'saveApp' }, 'Save')));
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const { data, problems } = readForm(form, { fields: APP_FIELDS });
    if (problems.length) { errs.replaceChildren(...problems.map((p) => h('div', {}, '• ' + p))); return; }
    const doc = { latestVersionCode: 0, minVersionCode: 0, ...data, updatedAt: new Date().toISOString() };
    try {
      await B().set('meta', 'app', clean(doc));
      await B().audit({ action: 'edit', collection: 'meta', docId: 'app', summary: `App ${doc.latestVersionName || ''} (${doc.latestVersionCode})` });
      toast('Saved. Phones see it within seconds.');
    } catch (err) { console.error(err); errs.textContent = 'Could not save: ' + (err.message || err); }
  });
  return h('div', {},
    h('h1', {}, 'App & updates'),
    h('div', { class: 'card' }, h('h3', {}, 'How app updates reach phones'),
      h('ol', {},
        h('li', {}, 'A developer raises the version in pubspec.yaml and runs the release script (apps/mobile/tool/release.ps1 on Windows, release.sh on Linux). It builds the app and publishes it on GitHub; the ', h('a', { href: 'download/', target: '_blank' }, 'download page'), ' always offers the newest one.'),
        h('li', {}, 'Here, press "Use latest release" and Save.'),
        h('li', {}, 'Every phone with an older version shows "Update available" with a download button. Content changes (numbers, hospitals, guides, announcements) never need an app update.'))),
    rel,
    form);
}

/* ---------- admins ---------- */
async function adminsScreen() {
  const admins = (await B().list('admins')).sort((a, b) => (a.email || a.id).localeCompare(b.email || b.id));
  const me = (state.user.email || '').toLowerCase();
  const email = h('input', { type: 'email', placeholder: 'friend@gmail.com', required: true, id: 'newAdmin' });
  const role = h('select', {}, h('option', { value: 'editor' }, 'Editor: can change content and donors'), h('option', { value: 'owner' }, 'Owner: also manages admins'));
  const add = async (e) => {
    e.preventDefault();
    const id = email.value.trim().toLowerCase();
    if (!/^[^\s@/]+@[^\s@/]+\.[^\s@/]+$/.test(id)) { toast('Enter a valid e-mail address', true); return; }
    try {
      await B().set('admins', id, { role: role.value, email: id, addedBy: me, addedAt: new Date().toISOString() });
      await B().audit({ action: 'add', collection: 'admins', docId: id, summary: `${id} as ${role.value}` });
      toast(`${id} can now sign in with Google.`); render();
    } catch (err) { console.error(err); toast('Could not add: ' + (err.message || err), true); }
  };
  const remove = async (a) => {
    if (!confirm(`Remove ${a.email || a.id} from the admins?`)) return;
    try {
      await B().del('admins', a.id);
      await B().audit({ action: 'delete', collection: 'admins', docId: a.id, summary: a.email || a.id });
      toast('Removed.'); render();
    } catch (err) { console.error(err); toast('Could not remove: ' + (err.message || err), true); }
  };
  return h('div', {},
    h('h1', {}, 'Admins'),
    h('p', { class: 'hint' }, 'People listed here can sign in to this panel with their Google account. Everyone else is refused, even if they sign in.'),
    h('div', { class: 'tablewrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['Google account', 'Role', 'Added by', 'Added'].map((x) => h('th', {}, x)), h('th', {}))),
      h('tbody', {}, admins.map((a) => h('tr', {},
        h('td', {}, a.email || a.id, (a.email || a.id) === me ? h('span', { class: 'badge' }, 'you') : null),
        h('td', {}, a.role === 'owner' ? 'Owner' : 'Editor'), h('td', {}, a.addedBy || ''), h('td', {}, (a.addedAt || '').slice(0, 10)),
        h('td', { class: 'actions' }, isOwner() && (a.email || a.id) !== me ? h('button', { class: 'danger', onclick: () => remove(a) }, 'Remove') : null)))))),
    isOwner()
      ? h('form', { class: 'card stack', onsubmit: add }, h('h3', {}, 'Add an admin'),
        h('label', { class: 'field' }, 'Their Google (Gmail) address', email), h('label', { class: 'field' }, 'Role', role),
        h('div', { class: 'row' }, h('button', { class: 'primary', type: 'submit' }, 'Add admin')))
      : h('p', { class: 'hint' }, 'Only owners can add or remove admins.'));
}

/* ---------- start ---------- */
function start() {
  if (start.done) return; start.done = true;
  if (!B().configured) { render(); return; }
  B().onAuth(async (user) => {
    state.user = user; state.role = null; state.adminError = ''; state.data = {};
    if (user) {
      try { state.role = await B().role(user); }
      catch (e) { console.error(e); state.adminError = (e && (e.code || e.message)) || 'unknown error'; }
    }
    render();
  });
}
window.addEventListener('backend-ready', start);
if (window.JoruriBackend) start();
render();
