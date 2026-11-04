// National emergency numbers, checked against official sources on 2026-11-04.
//   node emergency_numbers.mjs            → rewrites apps/mobile/assets/seed/emergency_numbers.json
//   node emergency_numbers.mjs --publish  → also writes them to Firestore and sends them to phones
import fs from 'node:fs';

const CHECKED = '2026-11-04';
const POLICE = { sourceName: 'Bangladesh Police — Hot Line Number', sourceUrl: 'https://www.police.gov.bd/en/hot_line_number' };
const FIRE = { sourceName: 'Fire Service and Civil Defence', sourceUrl: 'https://fireservice.gov.bd/' };
const ok = (src, note) => ({ status: 'verified', ...src, checkedOn: CHECKED, note });
const notYet = (src, note) => ({ status: 'unverified', ...src, checkedOn: CHECKED, note });

export const numbers = [
  {
    id: 'bd-999', number: '999', category: 'national', alsoCovers: ['police', 'fire', 'ambulance'],
    name: { en: 'National Emergency Service', bn: 'জাতীয় জরুরি সেবা' },
    description: {
      en: 'Police, fire service and ambulance. Toll-free, 24 hours, works with zero balance. The ambulance itself is not free.',
      bn: 'পুলিশ, ফায়ার সার্ভিস ও অ্যাম্বুলেন্স। টোল-ফ্রি, ২৪ ঘণ্টা, ব্যালেন্স না থাকলেও কল করা যায়। অ্যাম্বুলেন্স সেবা নিজে বিনা মূল্যে নয়।',
    },
    verification: ok(POLICE, 'Listed as "জরুরী সেবা ৯৯৯" on the Bangladesh Police and Fire Service websites (checked 2026-11-04).'),
  },
  {
    id: 'bd-police-hq', number: '01320001223', category: 'police',
    name: { en: 'Police Headquarters control room', bn: 'পুলিশ সদর দপ্তরের কন্ট্রোল রুম' },
    description: {
      en: '24 hours, for emergencies and law-and-order problems anywhere in the country. Other lines: 01320-001300, 01320-001299.',
      bn: '২৪ ঘণ্টা, দেশের যেকোনো স্থানের জরুরি ও আইনশৃঙ্খলা সমস্যার জন্য। অন্য নম্বর: ০১৩২০-০০১৩০০, ০১৩২০-০০১২৯৯।',
    },
    verification: notYet({ sourceName: 'Dhaka Tribune (BSS), Home Ministry press release, 2 Feb 2026', sourceUrl: 'https://www.dhakatribune.com/bangladesh/dhaka/402398/police-hq-rolls-out-24-7-control-room-mobile' },
      'Announced by Police Headquarters through a Home Ministry press release (news report). Not yet listed on police.gov.bd.'),
  },
  {
    id: 'bd-102', number: '102', category: 'fire',
    name: { en: 'Fire Service', bn: 'ফায়ার সার্ভিস' },
    description: {
      en: 'Fire Service and Civil Defence hotline for fire, rescue and accidents. 24 hours. 999 also reaches the fire service.',
      bn: 'আগুন, উদ্ধার ও দুর্ঘটনায় ফায়ার সার্ভিস ও সিভিল ডিফেন্সের হটলাইন। ২৪ ঘণ্টা। ৯৯৯-এ কল করলেও ফায়ার সার্ভিস পাওয়া যায়।',
    },
    verification: ok(FIRE, 'Listed as "ফায়ার সার্ভিস ১০২" on the Fire Service and Bangladesh Police websites (checked 2026-11-04).'),
  },
  {
    id: 'bd-fire-hq', number: '02223355555', category: 'fire',
    name: { en: 'Fire Service headquarters control room', bn: 'ফায়ার সার্ভিস সদর দপ্তর নিয়ন্ত্রণ কক্ষ' },
    description: {
      en: 'Fire Service and Civil Defence headquarters, Dhaka. Use if 102 does not connect.',
      bn: 'ফায়ার সার্ভিস ও সিভিল ডিফেন্স সদর দপ্তর, ঢাকা। ১০২-এ সংযোগ না পেলে।',
    },
    verification: ok(FIRE, 'Given on fireservice.gov.bd under "জরুরি প্রয়োজনে" (checked 2026-11-04).'),
  },
  {
    id: 'bd-109', number: '109', category: 'womenChildren',
    name: { en: 'National helpline: violence against women and children', bn: 'নারী ও শিশু নির্যাতন প্রতিরোধে জাতীয় হেল্পলাইন' },
    description: {
      en: 'Toll-free, 24 hours. Rescue, legal and psychosocial support, and child marriage prevention.',
      bn: 'টোল-ফ্রি, ২৪ ঘণ্টা। উদ্ধার, আইনি ও মনো-সামাজিক সহায়তা এবং বাল্যবিবাহ প্রতিরোধ।',
    },
    verification: ok(POLICE, 'Listed as "নারী ও শিশু নির্যাতন ১০৯" on the Bangladesh Police website (checked 2026-11-04).'),
  },
  {
    id: 'bd-1098', number: '1098', category: 'womenChildren',
    name: { en: 'Child Helpline', bn: 'চাইল্ড হেল্পলাইন' },
    description: {
      en: 'For children, and for anyone worried about a child. Run by the Department of Social Services.',
      bn: 'শিশুদের জন্য, এবং কোনো শিশুকে নিয়ে উদ্বিগ্ন যে কারও জন্য। সমাজসেবা অধিদফতর পরিচালিত।',
    },
    verification: ok(POLICE, 'Listed as "শিশু সহায়তা ১০৯৮" on the Bangladesh Police website (checked 2026-11-04).'),
  },
  {
    id: 'bd-16263', number: '16263', category: 'health',
    name: { en: 'Shastho Batayon, national health call centre', bn: 'স্বাস্থ্য বাতায়ন, জাতীয় স্বাস্থ্য কল সেন্টার' },
    description: {
      en: 'Doctors give health advice by phone (press 0 after dialling). Run for the Directorate General of Health Services. Not an ambulance service. In 2026 the service had funding problems: if it does not answer, call 999.',
      bn: 'ফোনে ডাক্তারের স্বাস্থ্য পরামর্শ (ডায়াল করার পর ০ চাপুন)। স্বাস্থ্য অধিদপ্তরের সেবা। এটি অ্যাম্বুলেন্স সেবা নয়। ২০২৬ সালে সেবাটি অর্থসংকটে ছিল: কেউ না ধরলে ৯৯৯-এ কল করুন।',
    },
    verification: notYet({ sourceName: 'DGHS — Shastho Batayon 16263', sourceUrl: 'https://16263.dghs.gov.bd/' },
      'Official DGHS service; news in Feb 2026 reported it at risk of closure after months of unpaid salaries. Call once to confirm it answers, then mark verified.'),
  },
  {
    id: 'bd-1090', number: '1090', category: 'disaster',
    name: { en: 'Disaster early warning', bn: 'দুর্যোগের আগাম বার্তা' },
    description: {
      en: 'Recorded weather, cyclone and flood warnings. Toll-free.',
      bn: 'আবহাওয়া, ঘূর্ণিঝড় ও বন্যার আগাম সতর্কবার্তা (রেকর্ড করা)। টোল-ফ্রি।',
    },
    verification: ok(POLICE, 'Listed as "দুর্যোগের আগাম বার্তা ১০৯০" on the Bangladesh Police website (checked 2026-11-04).'),
  },
  {
    id: 'bd-16430', number: '16430', category: 'government',
    name: { en: 'Government legal aid helpline', bn: 'সরকারি আইনি সহায়তা হেল্পলাইন' },
    description: {
      en: 'Free legal advice and legal aid from the National Legal Aid Services Organisation. Toll-free.',
      bn: 'জাতীয় আইনগত সহায়তা প্রদান সংস্থার বিনা মূল্যে আইনি পরামর্শ ও সহায়তা। টোল-ফ্রি।',
    },
    verification: ok(POLICE, 'Listed as "সরকারী আইন সেবা ১৬৪৩০" on the Bangladesh Police website (checked 2026-11-04).'),
  },
  {
    id: 'bd-333', number: '333', category: 'government',
    name: { en: 'National call centre for government information and services', bn: 'সরকারি তথ্য ও সেবার জাতীয় কল সেন্টার' },
    description: {
      en: 'Information about government services and help with social problems. Not an emergency line.',
      bn: 'সরকারি সেবা সম্পর্কে তথ্য এবং সামাজিক সমস্যায় সহায়তা। এটি জরুরি লাইন নয়।',
    },
    verification: ok(POLICE, 'Listed as "সরকারী তথ্য সেবা ৩৩৩" on the Bangladesh Police and Fire Service websites (checked 2026-11-04).'),
  },
  {
    id: 'bd-106', number: '106', category: 'government',
    name: { en: 'Anti-Corruption Commission hotline', bn: 'দুর্নীতি দমন কমিশন (দুদক) হটলাইন' },
    description: {
      en: 'Report bribery or corruption by a government office. Toll-free. Not an emergency line.',
      bn: 'সরকারি দপ্তরে ঘুষ বা দুর্নীতির অভিযোগ জানাতে। টোল-ফ্রি। এটি জরুরি লাইন নয়।',
    },
    verification: ok(POLICE, 'Listed as "দুদক হটলাইন ১০৬" on the Bangladesh Police and Fire Service websites (checked 2026-11-04).'),
  },
];

const file = new URL('../../apps/mobile/assets/seed/emergency_numbers.json', import.meta.url);
fs.writeFileSync(file, JSON.stringify({ schemaVersion: 1, contentVersion: '2026-11-04.1', numbers }, null, 2) + '\n');
console.log(`${numbers.length} numbers written to the app's bundled data`);

if (process.argv.includes('--publish')) {
  const { listAll, commit, publishSnapshots } = await import('../lib/firestore.mjs');
  const now = new Date().toISOString();
  const live = await listAll('emergency_numbers');
  const keep = new Set(numbers.map((n) => n.id));
  await commit([
    ...numbers.map((n) => ({ set: [`emergency_numbers/${n.id}`, { ...n, published: true, updatedAt: now }] })),
    ...live.filter((n) => !keep.has(n.id)).map((n) => ({ del: `emergency_numbers/${n.id}` })),
  ]);
  // Published in display order (999 first): apps up to 1.2.0 do not sort.
  const order = new Map(numbers.map((n, i) => [n.id, i]));
  const published = (await listAll('emergency_numbers')).filter((n) => n.published).sort((a, b) => (order.get(a.id) ?? 99) - (order.get(b.id) ?? 99));
  console.log('content version', await publishSnapshots({ emergency_numbers: published }), `(${published.length} numbers live)`);
}
