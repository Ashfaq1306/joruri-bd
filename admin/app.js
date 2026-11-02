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
const CONTENT = ['emergency_numbers', 'guides', 'hospitals', 'pharmacies'];

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
const state = { user: null, view: 'dashboard', data: {}, search: '' };

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
function shell(content) {
  const nav = [['dashboard', 'Dashboard'], ['emergency_numbers', 'Emergency numbers'], ['hospitals', 'Hospitals & tests'],
    ['pharmacies', 'Pharmacies'], ['guides', 'Guides'], ['donors', 'Blood donors'], ['import', 'Import'], ['audit', 'Activity log']];
  return h('div', { class: 'layout' },
    h('aside', { class: 'side' },
      h('div', { class: 'brand' }, h('img', { src: 'logo.png', alt: '' }), h('div', {}, h('b', {}, 'Joruri BD'), h('small', {}, 'Admin'))),
      nav.map(([v, label]) => h('button', { class: 'navbtn' + (state.view === v ? ' on' : ''), 'data-view': v, onclick: () => go(v) }, label)),
      h('div', { class: 'who' }, h('small', {}, state.user?.email || ''), h('button', { class: 'link', onclick: () => B().signOut() }, 'Sign out'))),
    h('main', { class: 'main' }, content));
}
function go(view) { state.view = view; state.search = ''; render(); }

async function render() {
  const root = $('#app');
  if (!B()) { root.replaceChildren(h('p', { class: 'center' }, 'Loading…')); return; }
  if (!B().configured) { root.replaceChildren(setupScreen()); return; }
  if (!state.user) { root.replaceChildren(loginScreen()); return; }
  if (state.adminError) { root.replaceChildren(accessCheckFailedScreen()); return; }
  if (!state.admin) { root.replaceChildren(notAdminScreen()); return; }
  root.replaceChildren(shell(h('p', {}, 'Loading…')));
  try {
    const content = state.view === 'dashboard' ? await dashboard()
      : state.view === 'import' ? importScreen()
        : state.view === 'audit' ? await auditScreen()
          : await listScreen(state.view);
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
    h('p', { class: 'hint center' }, 'Signing in does not make you an admin. Only accounts added to the admin list in the Firebase console can change anything.'),
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
    h('p', {}, 'This account can sign in but is not on the admin list. To make it an admin, the project owner adds this UID as a document in the "admins" collection in the Firebase console (SETUP_ONLINE.md, step 9). It cannot be done from this website or the app.'),
    uidBox(), h('button', { onclick: () => B().signOut() }, 'Sign out'));
}
function accessCheckFailedScreen() {
  const locked = /permission/i.test(state.adminError || '');
  return h('div', { class: 'login card' }, h('h1', {}, locked ? 'Database is locked' : 'Could not check admin access'),
    locked
      ? h('p', {}, 'The live Firestore rules still deny all access, so this website cannot read the admin list or any data. That is expected until you decide to deploy the proposed rules (firebase/RULES_PROPOSAL.md). Nothing is wrong with your account.')
      : h('p', {}, 'The admin list could not be read (' + state.adminError + '). Check the internet connection and try again.'),
    uidBox(),
    h('div', { class: 'row' }, h('button', { onclick: () => location.reload() }, 'Try again'), h('button', { onclick: () => B().signOut() }, 'Sign out')));
}

async function dashboard() {
  const [meta, ...lists] = await Promise.all([B().getMeta(), ...['emergency_numbers', 'hospitals', 'pharmacies', 'guides', 'donors'].map((c) => load(c, true))]);
  const [numbers, hospitals, pharmacies, guides, donors] = lists;
  const stat = (label, n, view, sub) => h('button', { class: 'stat', onclick: () => go(view) }, h('b', {}, n), h('span', {}, label), sub ? h('small', {}, sub) : null);
  const unverified = numbers.filter((n) => n.verification?.status !== 'verified').length;
  return h('div', {},
    h('h1', {}, 'Dashboard'),
    h('div', { class: 'stats' },
      stat('Emergency numbers', numbers.length, 'emergency_numbers', unverified ? `${unverified} not checked yet` : 'all checked'),
      stat('Hospitals', hospitals.length, 'hospitals', `${hospitals.reduce((a, x) => a + (x.tests || []).length, 0)} test prices`),
      stat('Pharmacies', pharmacies.length, 'pharmacies'),
      stat('Guides', guides.length, 'guides', `${guides.filter((g) => g.reviewStatus === 'approved').length} doctor-approved`),
      stat('Blood donors', donors.length, 'donors', `${donors.filter((d) => d.source === 'app').length} signed up in the app`)),
    h('div', { class: 'card' }, h('h3', {}, 'How phones get your changes'),
      h('p', {}, `Every save raises the content version (now ${meta.version || 0}). Phones check it each time the app opens with internet and when they come back online, then download the new numbers, hospitals, pharmacies and guides. Donor changes are live immediately.`),
      numbers.length === 0 ? h('p', { class: 'warn' }, 'No emergency numbers online yet: phones keep the numbers built into the app. Import the app\'s seed files on the Import page to start.') : null));
}

async function listScreen(col) {
  const schema = SCHEMAS[col];
  const items = await load(col);
  const q = state.search.toLowerCase();
  const rows = items.filter((d) => !q || JSON.stringify(d).toLowerCase().includes(q))
    .sort((a, b) => String(schema.columns[0][1](a) || '').localeCompare(String(schema.columns[0][1](b) || '')));
  const search = h('input', { type: 'search', placeholder: 'Search…', value: state.search, id: 'search' });
  search.addEventListener('input', () => { state.search = search.value; renderList(); });
  const tableWrap = h('div', { class: 'tablewrap' });
  function renderList() {
    const qq = state.search.toLowerCase();
    const shown = items.filter((d) => !qq || JSON.stringify(d).toLowerCase().includes(qq));
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
    schema.live ? h('p', { class: 'hint' }, 'Donor changes show in the app immediately. Donors who signed up in the app manage their own details; you can mark them checked or hide them.') : null,
    tableWrap);
}

/* ---------- edit form ---------- */
function field(f, value) {
  const name = f.k;
  const wrap = (input) => h('label', { class: 'field' + (f.type === 'checkbox' ? ' check' : '') }, f.type === 'checkbox' ? [input, f.label] : [f.label + (f.required ? ' *' : ''), input]);
  switch (f.type) {
    case 'checkbox': return wrap(h('input', { type: 'checkbox', name, checked: value ?? f.default ?? false }));
    case 'select': return wrap(h('select', { name }, f.options.map((o) => h('option', { value: o, selected: o === value ? 'selected' : null }, o))));
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
  const dialog = h('div', { class: 'overlay' }, form);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const { data, problems } = readForm(form, schema);
    if (problems.length) { errs.replaceChildren(...problems.map((p) => h('div', {}, '• ' + p))); return; }
    const id = existing?.id || schema.idFrom(data);
    const doc = clean({ ...(existing || {}), ...data, id, updatedAt: new Date().toISOString() });
    if (col === 'donors' && !existing) doc.source = 'admin';
    if (col === 'hospitals') doc.demo = false;
    try {
      await B().set(col, id, doc);
      await afterContentChange(existing ? 'edit' : 'add', col, id, doc.name?.en || doc.title?.en || doc.name || doc.number || '');
      const list = state.data[col] || []; const i = list.findIndex((x) => x.id === id);
      if (i >= 0) list[i] = doc; else list.push(doc);
      dialog.remove(); toast('Saved. Phones will update automatically.'); render();
    } catch (err) { console.error(err); errs.textContent = 'Could not save: ' + (err.message || err); }
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
  return h('div', {},
    h('h1', {}, 'Import'),
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

/* ---------- start ---------- */
function start() {
  if (start.done) return; start.done = true;
  if (!B().configured) { render(); return; }
  B().onAuth(async (user) => {
    state.user = user; state.admin = false; state.adminError = ''; state.data = {};
    if (user) {
      try { state.admin = await B().isAdmin(user.uid); }
      catch (e) { console.error(e); state.adminError = (e && (e.code || e.message)) || 'unknown error'; }
    }
    render();
  });
}
window.addEventListener('backend-ready', start);
if (window.JoruriBackend) start();
render();
