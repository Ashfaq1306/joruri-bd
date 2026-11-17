// Ambulance services from the MedicsBD "Ambulance Info" list.
//
// The live page (https://medicsbd.com/ambulance-info/, now /ambulance) showed
// no entries on 2026-11-17 ("The list is being updated"). The list below is
// the one MedicsBD published, as archived by the Wayback Machine on
// 2021-08-12. Only services with a mobile number are kept: mobile numbers
// still dial the same way. The landline-only entries use 7-digit Dhaka
// numbers from before the BTCL renumbering and cannot be dialled as printed,
// so they are left out until someone confirms the current number. Obvious
// typos were fixed (a dropped leading 0, "01713488411-12" = two numbers).
//
// Every entry is unverified: call once to confirm it answers, then mark it
// verified on the admin website.

const SOURCE = {
  sourceName: 'MedicsBD ambulance list (archived 12 Aug 2021)',
  sourceUrl: 'https://web.archive.org/web/20210812002048/https://medicsbd.com/ambulance-info/',
};
const CHECKED = '2026-11-17';
const NOTE = 'From the MedicsBD ambulance list (archived 2021-08-12; the live page had no entries on 2026-11-17). Not yet confirmed by phone.';

// [id, district, name en, name bn, address en, address bn, numbers...]
const rows = [
  // Dhaka
  ['al-markazul-islami', 'dhaka', 'Al-Markazul Islami ambulance service', 'আল-মারকাজুল ইসলামী অ্যাম্বুলেন্স সার্ভিস',
    '21/17 Babar Road, Mohammadpur, Dhaka', '২১/১৭ বাবর রোড, মোহাম্মদপুর, ঢাকা', '01819732905'],
  ['evercare-dhaka', 'dhaka', 'Evercare Hospital Dhaka (formerly Apollo)', 'এভারকেয়ার হাসপাতাল ঢাকা (সাবেক অ্যাপোলো)',
    'Plot 81, Block E, Bashundhara R/A, Dhaka', 'প্লট ৮১, ব্লক ই, বসুন্ধরা আ/এ, ঢাকা', '01714090000', '01713063067'],
  ['aysha-memorial', 'dhaka', 'Aysha Memorial Specialised Hospital', 'আয়শা মেমোরিয়াল স্পেশালাইজড হাসপাতাল',
    '74/G Peak Square, Mohakhali, Dhaka', '৭৪/জি পিক স্কয়ার, মহাখালী, ঢাকা', '01919372647', '01915490007'],
  ['cmh-dhaka', 'dhaka', 'CMH Dhaka, 24-hour ambulance', 'সিএমএইচ ঢাকা, ২৪ ঘণ্টা অ্যাম্বুলেন্স',
    'Combined Military Hospital, Dhaka Cantonment (Emergency & Casualty)', 'সম্মিলিত সামরিক হাসপাতাল, ঢাকা সেনানিবাস (জরুরি বিভাগ)', '01769013311', '01724579521'],
  ['comfort-nursing-home', 'dhaka', 'Comfort Nursing Home', 'কমফোর্ট নার্সিং হোম',
    '167/B Green Road, Dhanmondi, Dhaka', '১৬৭/বি গ্রিন রোড, ধানমন্ডি, ঢাকা', '01731956033', '01552468377'],
  ['criticare-ems', 'dhaka', 'Criticare EMS', 'ক্রিটিকেয়ার ইএমএস',
    'A.K. Complex (2nd floor), 19 Green Road, Dhaka', 'এ.কে. কমপ্লেক্স (২য় তলা), ১৯ গ্রিন রোড, ঢাকা', '01711191947'],
  ['dagma-hospital', 'dhaka', 'Dagma Diagnostic Hospital', 'ডাগমা ডায়াগনস্টিক হাসপাতাল',
    'Cha-88/1 Bir Uttam Rafiqul Islam Avenue, North Badda, Dhaka', 'ছ-৮৮/১ বীর উত্তম রফিকুল ইসলাম এভিনিউ, উত্তর বাড্ডা, ঢাকা', '01921088076'],
  ['day-night-ambulance', 'dhaka', 'Day-Night Ambulance Service', 'ডে-নাইট অ্যাম্বুলেন্স সার্ভিস',
    'Dhaka', 'ঢাকা', '01711544328'],
  ['haf-hospital', 'dhaka', 'H.A.F. General Hospital', 'এইচ.এ.এফ. জেনারেল হাসপাতাল',
    'Cha-88/5 Hasen Uddin Road, North Badda, Dhaka', 'ছ-৮৮/৫ হাসেন উদ্দিন রোড, উত্তর বাড্ডা, ঢাকা', '01741331446'],
  ['ibrahim-cardiac', 'dhaka', 'Ibrahim Cardiac Hospital, 24-hour ambulance', 'ইব্রাহিম কার্ডিয়াক হাসপাতাল, ২৪ ঘণ্টা অ্যাম্বুলেন্স',
    'Shahbag, Dhaka', 'শাহবাগ, ঢাকা', '01713003004'],
  ['panjeri-hospital', 'dhaka', 'Panjeri Hospital', 'পাঞ্জেরী হাসপাতাল',
    'K-11/1 Shahjahanpur bus stand, Progoti Sarani, Dhaka', 'কে-১১/১ শাহজাহানপুর বাসস্ট্যান্ড, প্রগতি সরণি, ঢাকা', '01678074437', '01727360727'],
  ['rafa-medical', 'dhaka', 'Rafa Medical', 'রাফা মেডিকেল',
    'Insurance Academy Bhaban, 53 Mohakhali TB Gate, Dhaka', 'ইন্স্যুরেন্স একাডেমি ভবন, ৫৩ মহাখালী টিবি গেট, ঢাকা', '01975090807'],
  ['shahabuddin-medical', 'dhaka', 'Shahabuddin Medical College Hospital', 'শাহাবুদ্দিন মেডিকেল কলেজ হাসপাতাল',
    'House 12, Road 113/A, Gulshan 2, Dhaka', 'বাড়ি ১২, রোড ১১৩/এ, গুলশান ২, ঢাকা', '01716777790', '01919777790'],
  ['united-hospital', 'dhaka', 'United Hospital', 'ইউনাইটেড হাসপাতাল',
    'Gulshan, Dhaka', 'গুলশান, ঢাকা', '01914001326'],
  ['modern-ambulance', 'dhaka', 'Modern Ambulance Service', 'মডার্ন অ্যাম্বুলেন্স সার্ভিস',
    'PG Hospital gate 1, Shahbag, Dhaka', 'পিজি হাসপাতাল ১ নম্বর গেট, শাহবাগ, ঢাকা', '01711450839', '01933342273', '01924860108'],
  ['labaid-dhanmondi', 'dhaka', 'Labaid Hospital', 'ল্যাবএইড হাসপাতাল',
    'House 6, Road 4, Dhanmondi, Dhaka', 'বাড়ি ৬, রোড ৪, ধানমন্ডি, ঢাকা', '01713330088', '01713091940'],
  ['desh-ambulance', 'dhaka', 'Desh Ambulance Service', 'দেশ অ্যাম্বুলেন্স সার্ভিস',
    '82 East Ahmed Nagar, Mirpur, Dhaka', '৮২ পূর্ব আহমেদ নগর, মিরপুর, ঢাকা', '01790509607'],
  ['ad-din-dhaka', 'dhaka', 'Ad-Din Medical College Hospital', 'আদ্-দ্বীন মেডিকেল কলেজ হাসপাতাল',
    '2 Bara Moghbazar, Outer Circular Road, Dhaka', '২ বড় মগবাজার, আউটার সার্কুলার রোড, ঢাকা', '01713488411', '01713488412'],
  ['islami-bank-mirpur', 'dhaka', 'Islami Bank Hospital Mirpur', 'ইসলামী ব্যাংক হাসপাতাল মিরপুর',
    'Plot 31, Main Road 3, Begum Rokeya Sarani, Mirpur, Dhaka', 'প্লট ৩১, মেইন রোড ৩, বেগম রোকেয়া সরণি, মিরপুর, ঢাকা', '01992346634'],
  ['24-hours-ambulance', 'dhaka', '24 Hours Ambulance', '২৪ আওয়ার্স অ্যাম্বুলেন্স',
    'Moghbazar, Airport Road, Basabo and Dhanmondi, Dhaka', 'মগবাজার, এয়ারপোর্ট রোড, বাসাবো ও ধানমন্ডি, ঢাকা', '01911125156', '01710060020'],
  // Chattogram
  ['alif-ambulance', 'chattogram', 'Alif Ambulance', 'আলিফ অ্যাম্বুলেন্স',
    'Panchlaish, Chattogram', 'পাঁচলাইশ, চট্টগ্রাম', '01701777782'],
  ['afc-fortis-ctg', 'chattogram', 'AFC Health Fortis Heart Institute', 'এএফসি হেলথ ফর্টিস হার্ট ইনস্টিটিউট',
    '12/12 O.R. Nizam Road, Chattogram', '১২/১২ ও.আর. নিজাম রোড, চট্টগ্রাম', '01933226666'],
  ['sts-apollo-ctg', 'chattogram', 'STS Chattogram Apollo Hospital', 'এসটিএস চট্টগ্রাম অ্যাপোলো হাসপাতাল',
    '3095/A O.R. Nizam Road (GEC/Golpahar), Panchlaish, Chattogram', '৩০৯৫/এ ও.আর. নিজাম রোড (গোলপাহাড়), পাঁচলাইশ, চট্টগ্রাম', '01714162759'],
  ['cmch', 'chattogram', 'Chattogram Medical College Hospital', 'চট্টগ্রাম মেডিকেল কলেজ হাসপাতাল',
    '57 K.B. Fazlul Kader Road, Panchlaish, Chattogram', '৫৭ কে.বি. ফজলুল কাদের রোড, পাঁচলাইশ, চট্টগ্রাম', '01819637685'],
  ['islami-bank-ctg', 'chattogram', 'Islami Bank Hospital Chattogram', 'ইসলামী ব্যাংক হাসপাতাল চট্টগ্রাম',
    '3 Sheikh Mujib Road, Agrabad, Chattogram', '৩ শেখ মুজিব রোড, আগ্রাবাদ, চট্টগ্রাম', '01731253990'],
  // Cumilla
  ['cumilla-trauma', 'cumilla', 'Cumilla Trauma Centre', 'কুমিল্লা ট্রমা সেন্টার',
    '511 Nazrul Avenue, Cumilla', '৫১১ নজরুল এভিনিউ, কুমিল্লা', '01735274020'],
  ['gomti-hospital', 'cumilla', 'Cumilla Gomti Hospital', 'কুমিল্লা গোমতী হাসপাতাল',
    'Nazrul Avenue, Kandirpar, Cumilla', 'নজরুল এভিনিউ, কান্দিরপাড়, কুমিল্লা', '01842798083'],
  ['eastern-medical', 'cumilla', 'Eastern Medical College Hospital', 'ইস্টার্ন মেডিকেল কলেজ হাসপাতাল',
    'Kabila, Dhaka–Chattogram highway, Burichang, Cumilla', 'কাবিলা, ঢাকা–চট্টগ্রাম মহাসড়ক, বুড়িচং, কুমিল্লা', '01730014800', '01717031411', '01748800590'],
  // Rajshahi
  ['islami-bank-rajshahi', 'rajshahi', 'Islami Bank Medical College Hospital', 'ইসলামী ব্যাংক মেডিকেল কলেজ হাসপাতাল',
    'Medical College Road, Rajshahi', 'মেডিকেল কলেজ রোড, রাজশাহী', '01763930101'],
  // Khulna
  ['ad-din-akij', 'khulna', 'Ad-Din Akij Medical College Hospital', 'আদ্-দ্বীন আকিজ মেডিকেল কলেজ হাসপাতাল',
    'Boikali, Khulna', 'বৈকালী, খুলনা', '01713488422'],
  ['khulna-city-medical', 'khulna', 'Khulna City Medical College Hospital', 'খুলনা সিটি মেডিকেল কলেজ হাসপাতাল',
    '33 KDA Avenue, Royal Mor, Khulna', '৩৩ কেডিএ এভিনিউ, রয়েল মোড়, খুলনা', '01858209392'],
  ['bd-eye-khulna', 'khulna', 'Bangladesh Eye Hospital, Khulna', 'বাংলাদেশ আই হাসপাতাল, খুলনা',
    '9/B Majid Sarani, Shibbari, Khulna', '৯/বি মজিদ সরণি, শিববাড়ি, খুলনা', '01799209075'],
  ['gazi-medical', 'khulna', 'Gazi Medical College Hospital', 'গাজী মেডিকেল কলেজ হাসপাতাল',
    '19-21 Majid Sarani, Sonadanga, Khulna', '১৯-২১ মজিদ সরণি, সোনাডাঙ্গা, খুলনা', '01779656722'],
];

export const ambulances = rows.map(([id, districtId, en, bn, addrEn, addrBn, number, ...others]) => ({
  id: `amb-${id}`,
  number,
  category: 'ambulance',
  districtId,
  name: { en, bn },
  address: { en: addrEn, bn: addrBn },
  description: {
    en: 'Private or hospital ambulance. Ask the fare before it comes. In a life-threatening emergency call 999 first.',
    bn: 'বেসরকারি বা হাসপাতালের অ্যাম্বুলেন্স। আসার আগে ভাড়া জেনে নিন। জীবন-সংকটে আগে ৯৯৯-এ কল করুন।',
  },
  otherNumbers: others,
  verification: { status: 'unverified', ...SOURCE, checkedOn: CHECKED, note: NOTE },
}));

// Sanity checks: every number is a mobile number, ids are unique.
for (const a of ambulances) {
  for (const n of [a.number, ...a.otherNumbers]) {
    if (!/^01[3-9]\d{8}$/.test(n)) throw new Error(`${a.id}: bad number ${n}`);
  }
}
if (new Set(ambulances.map((a) => a.id)).size !== ambulances.length) throw new Error('duplicate ambulance id');
