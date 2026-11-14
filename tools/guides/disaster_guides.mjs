// Disaster guides: what to do before, during and after each hazard that
// Bangladesh's warning services announce. Written from the government's
// Standing Orders on Disaster, BMD and CPP signal guidance, FFWC, IFRC/BDRCS
// and WHO advice (see `sources` of each guide). Status "draft" until the
// team has them checked by the Department of Disaster Management or BDRCS.
//
//   node tools/guides/disaster_guides.mjs          → updates apps/mobile/assets/seed/guides.json
//   node tools/guides/disaster_guides.mjs --publish → also updates Firestore (every phone)
import fs from 'node:fs';

const SOD = 'https://modmr.gov.bd/site/page/7bf8db41-a4e6-4c6c-b4a7-01e0e9d6bf33/Standing-Orders-on-Disaster';
const BMD = 'https://bmd.gov.bd';
const CAP = 'https://cap.bmd.gov.bd';
const CPP = 'https://cpp.gov.bd';
const FFWC = 'http://www.ffwc.gov.bd';
const DDM = 'https://ddm.gov.bd';
const BDRCS = 'https://bdrcs.org';
const IFRC = 'https://www.ifrc.org/document/international-first-aid-resuscitation-and-education-guidelines';
const WHO_HEAT = 'https://www.who.int/news-room/fact-sheets/detail/climate-change-heat-and-health';
const SHAKEOUT = 'https://www.shakeout.org/dropcoverholdon/';
const AEAS = 'https://crisisresponse.google/android-alerts/';

const L = (en, bn) => ({ en, bn });
/** Pairs of [en, bn] lines → { en: [...], bn: [...] } */
const lines = (...pairs) => ({ en: pairs.map((p) => p[0]), bn: pairs.map((p) => p[1]) });

export const disasterGuides = [
  {
    id: 'flood', kind: 'disaster', icon: 'flood', title: L('Flood', 'বন্যা'),
    prepare: lines(
      ['Follow the flood warnings: keep Joruri BD alerts on, listen to radio or TV, or call 1090 (free) for the forecast.', 'বন্যার সতর্কবার্তা খেয়াল রাখুন: জরুরি বিডির সতর্কবার্তা চালু রাখুন, রেডিও-টিভি শুনুন, অথবা পূর্বাভাসের জন্য ১০৯০-এ (টোল-ফ্রি) কল করুন।'],
      ['Know your nearest flood shelter or high ground, and a safe way to get there.', 'কাছের বন্যা আশ্রয়কেন্দ্র বা উঁচু জায়গা কোথায় এবং সেখানে যাওয়ার নিরাপদ পথ কোনটি, আগেই জেনে রাখুন।'],
      ['Pack an emergency bag: dry food (chira, muri, gur), drinking water, water purification tablets, ORS, regular medicines, a torch, and a charged phone or power bank.', 'জরুরি ব্যাগ গুছিয়ে রাখুন: শুকনো খাবার (চিড়া, মুড়ি, গুড়), খাবার পানি, পানি বিশুদ্ধকরণ ট্যাবলেট, ওরস্যালাইন, নিয়মিত ওষুধ, টর্চ এবং চার্জ দেওয়া ফোন বা পাওয়ার ব্যাংক।'],
      ['Put NID cards, land papers and certificates in a sealed plastic bag and keep them high up.', 'জাতীয় পরিচয়পত্র, জমির দলিল ও সনদপত্র পলিথিনের ব্যাগে মুখ বন্ধ করে উঁচু জায়গায় রাখুন।'],
      ['Raise a platform (macha) for food grain, seeds and fodder, and plan where your animals will go.', 'খাদ্যশস্য, বীজ ও গবাদিপশুর খাবারের জন্য উঁচু মাচা তৈরি করুন এবং পশুগুলো কোথায় রাখবেন তা ঠিক করে রাখুন।'],
    ),
    doNow: lines(
      ['When the water is rising, go to high ground or a flood shelter early. Move children, older people, pregnant women and people with disabilities first.', 'পানি বাড়তে থাকলে আগেভাগেই উঁচু জায়গা বা আশ্রয়কেন্দ্রে চলে যান। শিশু, বয়স্ক, গর্ভবতী নারী ও প্রতিবন্ধী ব্যক্তিদের আগে সরিয়ে নিন।'],
      ['Before water enters the house, switch off the electricity at the main switch and close the gas.', 'ঘরে পানি ঢোকার আগে মেইন সুইচ থেকে বিদ্যুৎ বন্ধ করুন এবং গ্যাসের চাবি বন্ধ করুন।'],
      ['Keep children away from the water at all times. Drowning is the biggest killer of children in floods.', 'শিশুদের সব সময় পানি থেকে দূরে রাখুন। বন্যায় শিশুমৃত্যুর প্রধান কারণ পানিতে ডুবে যাওয়া।'],
      ['Drink only boiled water, or water treated with purification tablets.', 'শুধু ফোটানো পানি বা বিশুদ্ধকরণ ট্যাবলেট দেওয়া পানি পান করুন।'],
      ['If you are trapped, go to the highest place (the roof), wave a bright cloth or a torch, and call 999.', 'আটকে পড়লে সবচেয়ে উঁচু জায়গায় (ছাদে) উঠুন, উজ্জ্বল রঙের কাপড় বা টর্চ নেড়ে সংকেত দিন এবং ৯৯৯-এ কল করুন।'],
    ),
    doNot: lines(
      ['Do not walk or drive through moving water. Water up to your knees can knock you down and carry a car away.', 'স্রোতের পানির মধ্যে দিয়ে হাঁটবেন না বা গাড়ি চালাবেন না। হাঁটুপানির স্রোতও মানুষকে ফেলে দিতে এবং গাড়ি ভাসিয়ে নিতে পারে।'],
      ['Do not touch electric poles, wires or switches that are in or near water.', 'পানিতে বা পানির কাছে থাকা বিদ্যুতের খুঁটি, তার বা সুইচ ছোঁবেন না।'],
      ['Do not eat food that has touched flood water.', 'বন্যার পানি লেগেছে এমন খাবার খাবেন না।'],
      ['Do not swim in flood water or let children play in it.', 'বন্যার পানিতে সাঁতার কাটবেন না, শিশুদেরও খেলতে দেবেন না।'],
    ),
    after: lines(
      ['Go home only when officials say it is safe. Check walls and floors for cracks before going in.', 'প্রশাসন নিরাপদ বললে তবেই বাড়ি ফিরুন। ঢোকার আগে দেয়াল ও মেঝেতে ফাটল আছে কি না দেখুন।'],
      ['Pump the tube well until the water runs clear, and keep boiling drinking water for some days.', 'টিউবওয়েলের পানি পরিষ্কার না হওয়া পর্যন্ত চাপুন, এবং কয়েক দিন খাবার পানি ফুটিয়ে পান করুন।'],
      ['Watch for snakes in the house and on paths.', 'ঘরে ও রাস্তায় সাপের ব্যাপারে সাবধান থাকুন।'],
      ['Wash hands with soap. For diarrhoea, give ORS after every loose stool.', 'সাবান দিয়ে হাত ধুয়ে নিন। ডায়রিয়া হলে প্রতিবার পাতলা পায়খানার পর ওরস্যালাইন খাওয়ান।'],
    ),
    getHelp: lines(
      ['Diarrhoea with signs of dehydration (very thirsty, sunken eyes, little urine), especially in a child or an older person.', 'ডায়রিয়ার সঙ্গে পানিশূন্যতার লক্ষণ (খুব পিপাসা, চোখ বসে যাওয়া, প্রস্রাব কমে যাওয়া), বিশেষ করে শিশু বা বয়স্কদের।'],
      ['High fever, a wound from debris, or a snake bite: go to the nearest health complex at once.', 'বেশি জ্বর, ভাঙা জিনিসে কেটে যাওয়া, বা সাপে কাটলে: সঙ্গে সঙ্গে কাছের স্বাস্থ্য কমপ্লেক্সে যান।'],
    ),
    whoToContact: L('999 for rescue. 1090 (free) for flood forecasts and weather warnings. The Union Parishad or Upazila disaster management committee for shelters and relief.', 'উদ্ধারের জন্য ৯৯৯। বন্যার পূর্বাভাস ও আবহাওয়া সতর্কবার্তার জন্য ১০৯০ (টোল-ফ্রি)। আশ্রয়কেন্দ্র ও ত্রাণের জন্য ইউনিয়ন পরিষদ বা উপজেলা দুর্যোগ ব্যবস্থাপনা কমিটি।'),
    callNumbers: ['999', '1090'], sources: [SOD, FFWC, DDM, BDRCS],
  },
  {
    id: 'cyclone', kind: 'disaster', icon: 'cyclone', title: L('Cyclone and storm surge', 'ঘূর্ণিঝড় ও জলোচ্ছ্বাস'),
    prepare: lines(
      ['Learn what the storm signals mean (Disaster alerts → Cyclone signals) and follow radio, TV, 1090 and the flags and megaphones of CPP volunteers.', 'বিপদ সংকেতগুলোর মানে জেনে নিন (দুর্যোগ সতর্কতা → ঘূর্ণিঝড় সংকেত) এবং রেডিও, টিভি, ১০৯০ ও সিপিপি স্বেচ্ছাসেবকদের পতাকা ও মাইকিং খেয়াল রাখুন।'],
      ['Know where your nearest cyclone shelter is and the safest way to reach it, also at night.', 'কাছের ঘূর্ণিঝড় আশ্রয়কেন্দ্র কোথায় এবং রাতেও সেখানে যাওয়ার নিরাপদ পথ কোনটি, জেনে রাখুন।'],
      ['Pack an emergency bag: dry food, drinking water, ORS, medicines, a torch, a radio, a power bank, some cash, and important papers in plastic.', 'জরুরি ব্যাগ গুছিয়ে রাখুন: শুকনো খাবার, খাবার পানি, ওরস্যালাইন, ওষুধ, টর্চ, রেডিও, পাওয়ার ব্যাংক, কিছু টাকা এবং পলিথিনে মোড়ানো দরকারি কাগজপত্র।'],
      ['Tie down the roof and tin sheets, and cut weak branches near the house.', 'ঘরের চাল ও টিন শক্ত করে বেঁধে দিন, বাড়ির কাছের দুর্বল ডালপালা কেটে ফেলুন।'],
      ['Fishing boats and trawlers: come back to shore as soon as signal 3 or higher is announced.', 'মাছ ধরার নৌকা ও ট্রলার: ৩ বা তার বেশি নম্বর সংকেত ঘোষণা হলেই তীরে ফিরে আসুন।'],
    ),
    doNow: lines(
      ['Danger signal (5, 6, 7): take children, older people, pregnant women and people with disabilities to the cyclone shelter now. Move animals to a raised place (killa) if you can.', 'বিপদ সংকেত (৫, ৬, ৭): শিশু, বয়স্ক, গর্ভবতী নারী ও প্রতিবন্ধী ব্যক্তিদের এখনই আশ্রয়কেন্দ্রে নিয়ে যান। সম্ভব হলে গবাদিপশু উঁচু জায়গায় (কিল্লায়) সরিয়ে নিন।'],
      ['Great danger signal (8, 9, 10): everyone go to the cyclone shelter or a strong concrete building now. Do not wait for the wind to start.', 'মহাবিপদ সংকেত (৮, ৯, ১০): সবাই এখনই আশ্রয়কেন্দ্র বা মজবুত পাকা ভবনে চলে যান। বাতাস শুরু হওয়ার অপেক্ষা করবেন না।'],
      ['Before leaving, switch off electricity and gas, and wrap valuables and food grain in plastic or bury them.', 'বের হওয়ার আগে বিদ্যুৎ ও গ্যাস বন্ধ করুন, মূল্যবান জিনিস ও খাদ্যশস্য পলিথিনে মুড়ে রাখুন বা মাটিতে পুঁতে রাখুন।'],
      ['In the shelter, stay away from windows and stay until officials say the storm is over.', 'আশ্রয়কেন্দ্রে জানালা থেকে দূরে থাকুন এবং প্রশাসন ঝড় শেষ না বলা পর্যন্ত সেখানেই থাকুন।'],
      ['If you cannot reach a shelter, stay in the strongest room of a pucca house, under a strong table, away from windows.', 'আশ্রয়কেন্দ্রে যেতে না পারলে পাকা বাড়ির সবচেয়ে মজবুত ঘরে, শক্ত টেবিলের নিচে, জানালা থেকে দূরে থাকুন।'],
    ),
    doNot: lines(
      ['Do not go out when the wind suddenly stops: it may be the eye of the storm, and the wind will come back from the other side.', 'হঠাৎ বাতাস থেমে গেলে বাইরে যাবেন না: এটি ঝড়ের কেন্দ্র (চোখ) হতে পারে, একটু পরেই উল্টো দিক থেকে আবার প্রবল বাতাস আসবে।'],
      ['Do not go to the sea or river, or out on a boat, until the signals are lowered.', 'সংকেত নামানো না পর্যন্ত সমুদ্র বা নদীতে যাবেন না, নৌকায় উঠবেন না।'],
      ['Do not stay in a kutcha house or under trees during the storm.', 'ঝড়ের সময় কাঁচা ঘরে বা গাছের নিচে থাকবেন না।'],
      ['Do not touch fallen electric wires.', 'ছিঁড়ে পড়া বিদ্যুতের তার ছোঁবেন না।'],
    ),
    after: lines(
      ['Wait for the official all-clear before going home.', 'বাড়ি ফেরার আগে প্রশাসনের ঘোষণার অপেক্ষা করুন।'],
      ['Watch for fallen wires, broken trees, weak buildings and snakes.', 'ছিঁড়ে পড়া তার, ভাঙা গাছ, দুর্বল ঘরবাড়ি ও সাপের ব্যাপারে সাবধান থাকুন।'],
      ['Surge water makes ponds and tube wells salty and dirty: drink only boiled or treated water.', 'জলোচ্ছ্বাসে পুকুর ও টিউবওয়েলের পানি লবণাক্ত ও দূষিত হয়: শুধু ফোটানো বা বিশুদ্ধ করা পানি পান করুন।'],
      ['Help injured neighbours and tell officials or 999 about anyone missing.', 'আহত প্রতিবেশীদের সাহায্য করুন এবং কেউ নিখোঁজ থাকলে প্রশাসন বা ৯৯৯-কে জানান।'],
    ),
    getHelp: lines(
      ['Anyone injured, trapped or missing: call 999.', 'কেউ আহত, আটকে পড়া বা নিখোঁজ হলে: ৯৯৯-এ কল করুন।'],
      ['Diarrhoea with dehydration, or a wound that becomes red, swollen or smelly: go to the health complex.', 'পানিশূন্যতাসহ ডায়রিয়া, অথবা ক্ষত লাল হয়ে ফুলে গেলে বা দুর্গন্ধ হলে: স্বাস্থ্য কমপ্লেক্সে যান।'],
    ),
    whoToContact: L('999 for rescue. 1090 (free) for the latest signal and forecast. CPP volunteers and the Union disaster management committee for shelters and evacuation.', 'উদ্ধারের জন্য ৯৯৯। সর্বশেষ সংকেত ও পূর্বাভাসের জন্য ১০৯০ (টোল-ফ্রি)। আশ্রয়কেন্দ্র ও সরিয়ে নেওয়ার জন্য সিপিপি স্বেচ্ছাসেবক ও ইউনিয়ন দুর্যোগ ব্যবস্থাপনা কমিটি।'),
    callNumbers: ['999', '1090'], sources: [SOD, CPP, BMD, CAP],
  },
  {
    id: 'earthquake', kind: 'disaster', icon: 'earthquake', title: L('Earthquake', 'ভূমিকম্প'),
    prepare: lines(
      ['No one can predict an earthquake. Turn on "Earthquake alerts" on your Android phone (Settings → Safety & emergency, or Location → Advanced). It can warn you a few seconds before strong shaking reaches you.', 'ভূমিকম্পের আগাম পূর্বাভাস কেউ দিতে পারে না। অ্যান্ড্রয়েড ফোনে "Earthquake alerts" চালু করুন (Settings → Safety & emergency, অথবা Location → Advanced)। জোরালো কাঁপুনি পৌঁছানোর কয়েক সেকেন্ড আগে এটি সতর্ক করতে পারে।'],
      ['Fix tall furniture, shelves, the fridge and gas cylinders to the wall. Keep heavy things on low shelves.', 'উঁচু আসবাব, তাক, ফ্রিজ ও গ্যাস সিলিন্ডার দেয়ালের সঙ্গে আটকে দিন। ভারী জিনিস নিচের তাকে রাখুন।'],
      ['Find the safe spot in every room (under a strong table, against an inside wall) and practise Drop, Cover, Hold On with your family.', 'প্রতিটি ঘরে নিরাপদ জায়গা ঠিক করুন (মজবুত টেবিলের নিচে, ভেতরের দেয়ালের পাশে) এবং পরিবারের সবাই মিলে "বসে পড়ুন, মাথা ঢাকুন, ধরে থাকুন" অনুশীলন করুন।'],
      ['Keep shoes, a torch, a whistle and an emergency bag near your bed.', 'বিছানার কাছে জুতা, টর্চ, বাঁশি ও জরুরি ব্যাগ রাখুন।'],
      ['Agree on a meeting place outside, away from buildings and electric wires.', 'বাইরে ভবন ও বিদ্যুতের তার থেকে দূরে একটি জায়গা ঠিক করুন, যেখানে সবাই একত্র হবেন।'],
    ),
    doNow: lines(
      ['DROP to your hands and knees.', 'বসে পড়ুন: হাঁটু ও হাতের ওপর ভর দিয়ে মেঝেতে বসে পড়ুন।'],
      ['COVER your head and neck under a strong table. If there is none, crouch against an inside wall and cover your head with your arms.', 'মাথা ঢাকুন: মজবুত টেবিলের নিচে মাথা ও ঘাড় ঢেকে রাখুন। টেবিল না থাকলে ভেতরের দেয়াল ঘেঁষে বসে দুই হাতে মাথা ঢাকুন।'],
      ['HOLD ON until the shaking stops.', 'ধরে থাকুন: কাঁপুনি না থামা পর্যন্ত শক্ত করে ধরে থাকুন।'],
      ['Outside: move to an open place away from buildings, trees, electric poles and wires.', 'বাইরে থাকলে: ভবন, গাছ, বিদ্যুতের খুঁটি ও তার থেকে দূরে খোলা জায়গায় চলে যান।'],
      ['In a vehicle: stop in an open place and stay inside with the seat belt on.', 'গাড়িতে থাকলে: খোলা জায়গায় থামুন এবং সিটবেল্ট বেঁধে ভেতরেই থাকুন।'],
      ['When the shaking stops, turn off the gas and electricity and leave calmly by the stairs.', 'কাঁপুনি থামলে গ্যাস ও বিদ্যুৎ বন্ধ করে শান্তভাবে সিঁড়ি দিয়ে বের হোন।'],
    ),
    doNot: lines(
      ['Do not run outside or down the stairs while the building is shaking. Most injuries come from falling objects.', 'ভবন কাঁপার সময় দৌড়ে বাইরে বা সিঁড়িতে যাবেন না। বেশিরভাগ আঘাত হয় ওপর থেকে পড়া জিনিসে।'],
      ['Do not use the lift.', 'লিফট ব্যবহার করবেন না।'],
      ['Do not jump from a balcony or window.', 'বারান্দা বা জানালা দিয়ে লাফ দেবেন না।'],
      ['Do not light a match or lighter afterwards: there may be a gas leak.', 'ভূমিকম্পের পর দেশলাই বা লাইটার জ্বালাবেন না: গ্যাস লিক থাকতে পারে।'],
    ),
    after: lines(
      ['Expect aftershocks. Each time: Drop, Cover, Hold On.', 'আফটারশক (পরাঘাত) হতে পারে। প্রতিবার: বসে পড়ুন, মাথা ঢাকুন, ধরে থাকুন।'],
      ['If you are trapped: cover your mouth with cloth, tap on a pipe or wall or blow a whistle so rescuers can find you. Shout only as a last resort, to save strength and avoid breathing dust.', 'আটকে পড়লে: কাপড় দিয়ে মুখ ঢাকুন, পাইপ বা দেয়ালে টোকা দিন বা বাঁশি বাজান যাতে উদ্ধারকারীরা খুঁজে পান। শক্তি বাঁচাতে ও ধুলা এড়াতে একান্ত দরকার না হলে চিৎকার করবেন না।'],
      ['Do not go back into a cracked or damaged building until engineers say it is safe.', 'প্রকৌশলী নিরাপদ না বলা পর্যন্ত ফাটল ধরা বা ক্ষতিগ্রস্ত ভবনে ফিরে যাবেন না।'],
      ['If you smell gas: open doors and windows, do not touch switches, leave and call 999.', 'গ্যাসের গন্ধ পেলে: দরজা-জানালা খুলে দিন, সুইচে হাত দেবেন না, বেরিয়ে যান এবং ৯৯৯-এ কল করুন।'],
      ['On the coast after a strong earthquake, if the sea suddenly pulls back, go to high ground at once (tsunami).', 'উপকূলে জোরালো ভূমিকম্পের পর হঠাৎ সমুদ্রের পানি পিছিয়ে গেলে সঙ্গে সঙ্গে উঁচু জায়গায় চলে যান (সুনামি)।'],
    ),
    getHelp: lines(
      ['People trapped under rubble: call 999 and tell them exactly where. The Fire Service does rescue.', 'কেউ ধ্বংসস্তূপের নিচে আটকে থাকলে: ৯৯৯-এ কল করে ঠিক কোথায় তা জানান। ফায়ার সার্ভিস উদ্ধার করে।'],
      ['Crush injuries, heavy bleeding or head injuries: go to hospital at once.', 'চাপা পড়ার আঘাত, বেশি রক্তপাত বা মাথায় আঘাত: সঙ্গে সঙ্গে হাসপাতালে যান।'],
    ),
    whoToContact: L('999 for the Fire Service, ambulance and police. Fire Service: 102.', 'ফায়ার সার্ভিস, অ্যাম্বুলেন্স ও পুলিশের জন্য ৯৯৯। ফায়ার সার্ভিস: ১০২।'),
    callNumbers: ['999', '102'], sources: [SHAKEOUT, AEAS, SOD, IFRC],
  },
  {
    id: 'lightning', kind: 'disaster', icon: 'lightning', title: L('Lightning', 'বজ্রপাত'),
    prepare: lines(
      ['Lightning kills people in Bangladesh every year, mostly from April to June and in the afternoon. Check the weather before going to the field, river or haor.', 'বাংলাদেশে প্রতি বছর বজ্রপাতে মানুষ মারা যায়, বেশিরভাগই এপ্রিল থেকে জুনে এবং বিকেলে। মাঠ, নদী বা হাওরে যাওয়ার আগে আবহাওয়ার খবর নিন।'],
      ['Count from the flash to the thunder. If it is less than 30 seconds, go inside now, and wait 30 minutes after the last thunder.', 'বিদ্যুৎ চমকানোর পর বাজ পড়ার শব্দ পর্যন্ত গুনুন। ৩০ সেকেন্ডের কম হলে এখনই ঘরে ঢুকুন, এবং শেষ বজ্রধ্বনির পর ৩০ মিনিট অপেক্ষা করুন।'],
      ['If possible, put a lightning conductor (arrester) on your house.', 'সম্ভব হলে বাড়িতে বজ্রনিরোধক দণ্ড লাগান।'],
    ),
    doNow: lines(
      ['When the sky turns dark or you hear thunder, go inside a pucca building or a car with a metal roof at once.', 'আকাশ কালো হলে বা বাজের শব্দ শুনলেই সঙ্গে সঙ্গে পাকা ভবনে বা ধাতব ছাদের গাড়িতে ঢুকে পড়ুন।'],
      ['Caught in the open with no shelter: crouch low on the balls of your feet, heels together, head down and ears covered. Do not lie flat.', 'খোলা মাঠে আশ্রয় না থাকলে: পায়ের আঙুলের ওপর ভর দিয়ে গোড়ালি জোড়া করে মাথা নিচু করে বসে পড়ুন, কান ঢেকে রাখুন। মাটিতে শুয়ে পড়বেন না।'],
      ['Get out of ponds, rivers and boats.', 'পুকুর, নদী ও নৌকা থেকে উঠে আসুন।'],
      ['In a group, spread out at least 15 metres apart.', 'দলবদ্ধ থাকলে একে অপরের থেকে অন্তত ১৫ মিটার দূরে দূরে থাকুন।'],
      ['Indoors: stay away from windows, doors and metal pipes, and unplug the TV and other electric appliances.', 'ঘরের ভেতরে: জানালা, দরজা ও ধাতব পাইপ থেকে দূরে থাকুন, টিভি ও অন্যান্য বৈদ্যুতিক যন্ত্রের প্লাগ খুলে রাখুন।'],
    ),
    doNot: lines(
      ['Do not shelter under a tall tree, an electric pole or a mobile tower.', 'উঁচু গাছ, বিদ্যুতের খুঁটি বা মোবাইল টাওয়ারের নিচে আশ্রয় নেবেন না।'],
      ['Do not stay in an open field, on a rooftop or in water during a thunderstorm.', 'বজ্রঝড়ের সময় খোলা মাঠে, ছাদে বা পানিতে থাকবেন না।'],
      ['Do not hold metal objects such as a fishing rod, a plough or a metal-tipped umbrella.', 'মাছ ধরার ছিপ, লাঙল বা ধাতব মাথার ছাতার মতো ধাতব জিনিস হাতে রাখবেন না।'],
    ),
    after: lines(
      ['A person struck by lightning carries no electricity: you can touch them safely. Call 999 at once.', 'বজ্রাহত ব্যক্তির শরীরে বিদ্যুৎ থাকে না: নিরাপদে তাঁকে ধরতে পারেন। সঙ্গে সঙ্গে ৯৯৯-এ কল করুন।'],
      ['If they are not breathing, start CPR if you are trained, and keep going until help arrives.', 'শ্বাস না নিলে প্রশিক্ষণ থাকলে সিপিআর শুরু করুন এবং সাহায্য না আসা পর্যন্ত চালিয়ে যান।'],
      ['Cool burns with clean running water and keep the person warm.', 'পোড়া জায়গায় পরিষ্কার প্রবাহিত পানি ঢালুন এবং ব্যক্তিকে উষ্ণ রাখুন।'],
    ),
    getHelp: lines(
      ['Anyone struck by lightning must go to hospital, even if they seem fine: it can damage the heart and nerves.', 'বজ্রাহত যে কাউকে হাসপাতালে নিতে হবে, ভালো দেখালেও: এতে হৃদযন্ত্র ও স্নায়ুর ক্ষতি হতে পারে।'],
    ),
    whoToContact: L('999 for an ambulance. 1090 (free) for thunderstorm warnings.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। বজ্রঝড়ের সতর্কবার্তার জন্য ১০৯০ (টোল-ফ্রি)।'),
    callNumbers: ['999', '1090'], sources: [SOD, BMD, IFRC],
  },
  {
    id: 'landslide', kind: 'disaster', icon: 'landslide', title: L('Landslide', 'পাহাড় ধস'),
    prepare: lines(
      ['If you live on or below a hill slope (Chattogram, Cox\'s Bazar, Rangamati, Bandarban, Khagrachhari), know your nearest shelter and keep the emergency bag ready in the rainy season.', 'পাহাড়ের ঢালে বা পাদদেশে থাকলে (চট্টগ্রাম, কক্সবাজার, রাঙ্গামাটি, বান্দরবান, খাগড়াছড়ি) কাছের আশ্রয়কেন্দ্র কোথায় জেনে রাখুন এবং বর্ষায় জরুরি ব্যাগ প্রস্তুত রাখুন।'],
      ['Do not cut the hill or the trees on the slope around your house, and keep drains clear.', 'বাড়ির আশপাশের পাহাড় বা ঢালের গাছ কাটবেন না, নালা পরিষ্কার রাখুন।'],
      ['Know the warning signs: new cracks in the ground or walls, tilting trees or poles, muddy water from springs, small stones and soil falling.', 'বিপদের লক্ষণ চিনে রাখুন: মাটি বা দেয়ালে নতুন ফাটল, গাছ বা খুঁটি হেলে পড়া, ঝরনা থেকে ঘোলা পানি আসা, ছোট পাথর ও মাটি গড়িয়ে পড়া।'],
    ),
    doNow: lines(
      ['When heavy rain is forecast for the hill districts, or it has rained hard for a day or more, leave homes on or below slopes and go to a shelter, even at night.', 'পাহাড়ি জেলায় ভারী বৃষ্টির পূর্বাভাস থাকলে বা এক দিনের বেশি টানা ভারী বৃষ্টি হলে ঢালে বা পাদদেশের ঘর ছেড়ে আশ্রয়কেন্দ্রে যান, রাত হলেও।'],
      ['If you hear rumbling or see the ground moving, run sideways out of its path to higher, solid ground.', 'গুড়গুড় শব্দ শুনলে বা মাটি সরতে দেখলে ধসের পথ থেকে পাশের দিকে দৌড়ে উঁচু, শক্ত জায়গায় চলে যান।'],
      ['If you cannot escape, curl into a tight ball and protect your head.', 'পালাতে না পারলে গুটিসুটি হয়ে বসে দুই হাতে মাথা রক্ষা করুন।'],
    ),
    doNot: lines(
      ['Do not stay in a house at the foot of a hill during heavy rain.', 'ভারী বৃষ্টির সময় পাহাড়ের পাদদেশের ঘরে থাকবেন না।'],
      ['Do not cross a stream or a road covered by flowing mud.', 'কাদাস্রোতে ঢাকা ছড়া বা রাস্তা পার হবেন না।'],
      ['Do not go back for belongings while it is still raining.', 'বৃষ্টি চলতে থাকা অবস্থায় জিনিসপত্র আনতে ফিরে যাবেন না।'],
    ),
    after: lines(
      ['Stay away from the slide area: more slides can follow.', 'ধসের জায়গা থেকে দূরে থাকুন: আবারও ধস নামতে পারে।'],
      ['Tell 999 where people may be buried. Dig only if it is safe.', 'কেউ চাপা পড়ে থাকলে কোথায়, তা ৯৯৯-কে জানান। নিরাপদ হলে তবেই খোঁড়াখুঁড়ি করুন।'],
      ['Check for broken electric lines, gas and water pipes.', 'ছেঁড়া বিদ্যুতের তার, গ্যাস ও পানির পাইপ ভাঙা কি না দেখুন।'],
    ),
    getHelp: lines(
      ['Anyone buried, injured or missing: call 999.', 'কেউ চাপা পড়লে, আহত বা নিখোঁজ হলে: ৯৯৯-এ কল করুন।'],
    ),
    whoToContact: L('999 for the Fire Service and ambulance. 1090 (free) for heavy-rain warnings.', 'ফায়ার সার্ভিস ও অ্যাম্বুলেন্সের জন্য ৯৯৯। ভারী বৃষ্টির সতর্কবার্তার জন্য ১০৯০ (টোল-ফ্রি)।'),
    callNumbers: ['999', '1090'], sources: [SOD, CAP, DDM],
  },
  {
    id: 'severe-storm', kind: 'disaster', icon: 'storm', title: L('Nor\'wester and thunderstorm (Kalbaishakhi)', 'কালবৈশাখী ও বজ্রঝড়'),
    prepare: lines(
      ['Kalbaishakhi storms come suddenly from March to May, usually in the afternoon. Check the forecast or call 1090 before a river trip.', 'মার্চ থেকে মে মাসে কালবৈশাখী হঠাৎ আসে, সাধারণত বিকেলে। নদীপথে যাত্রার আগে পূর্বাভাস দেখুন বা ১০৯০-এ কল করুন।'],
      ['Tie down tin roofs and cut weak branches near the house.', 'টিনের চাল শক্ত করে বাঁধুন, বাড়ির কাছের দুর্বল ডালপালা কেটে ফেলুন।'],
    ),
    doNow: lines(
      ['Go inside a strong building as soon as the sky darkens and the wind rises.', 'আকাশ কালো হয়ে বাতাস বাড়তে শুরু করলেই মজবুত ভবনে ঢুকে পড়ুন।'],
      ['On a boat or launch: put on a life jacket and get to the nearest shore at once.', 'নৌকা বা লঞ্চে থাকলে: লাইফ জ্যাকেট পরুন এবং সঙ্গে সঙ্গে কাছের তীরে ভিড়ুন।'],
      ['Stay away from windows, tin sheets, billboards, trees and electric poles.', 'জানালা, টিন, বিলবোর্ড, গাছ ও বিদ্যুতের খুঁটি থেকে দূরে থাকুন।'],
      ['Follow the lightning steps: no open fields, no water, crouch low if caught outside.', 'বজ্রপাতের নিয়ম মানুন: খোলা মাঠে বা পানিতে থাকবেন না, বাইরে আটকে পড়লে নিচু হয়ে বসে পড়ুন।'],
    ),
    doNot: lines(
      ['Do not board an overloaded launch or boat, or travel while a storm signal is up for river ports.', 'অতিরিক্ত যাত্রী বোঝাই লঞ্চ বা নৌকায় উঠবেন না, নদীবন্দরে ঝড়ের সংকেত থাকলে যাত্রা করবেন না।'],
      ['Do not shelter under a tree, a tin shed or a weak wall.', 'গাছ, টিনের ছাউনি বা দুর্বল দেয়ালের নিচে আশ্রয় নেবেন না।'],
      ['Do not touch fallen electric wires.', 'ছিঁড়ে পড়া বিদ্যুতের তার ছোঁবেন না।'],
    ),
    after: lines(
      ['Watch for fallen wires and broken trees on the road.', 'রাস্তায় ছিঁড়ে পড়া তার ও ভাঙা গাছের ব্যাপারে সাবধান থাকুন।'],
      ['Help the injured and call 999 for a boat accident or anyone missing.', 'আহতদের সাহায্য করুন; নৌকাডুবি বা কেউ নিখোঁজ হলে ৯৯৯-এ কল করুন।'],
    ),
    getHelp: lines(
      ['Injuries from flying objects or falling trees, or anyone pulled from the water: go to hospital.', 'উড়ে আসা জিনিস বা গাছ পড়ে আহত হলে, অথবা কাউকে পানি থেকে তোলা হলে: হাসপাতালে নিন।'],
    ),
    whoToContact: L('999 for rescue and ambulance. 1090 (free) for storm warnings.', 'উদ্ধার ও অ্যাম্বুলেন্সের জন্য ৯৯৯। ঝড়ের সতর্কবার্তার জন্য ১০৯০ (টোল-ফ্রি)।'),
    callNumbers: ['999', '1090'], sources: [SOD, BMD, CAP],
  },
  {
    id: 'heatwave', kind: 'disaster', icon: 'heat', title: L('Heat wave', 'তাপপ্রবাহ'),
    prepare: lines(
      ['BMD calls 36–38°C a mild, 38–40°C a moderate, 40–42°C a severe and above 42°C a very severe heat wave.', 'আবহাওয়া অধিদপ্তরের হিসাবে ৩৬–৩৮° সেলসিয়াস মৃদু, ৩৮–৪০° মাঝারি, ৪০–৪২° তীব্র এবং ৪২°-এর বেশি অতি তীব্র তাপপ্রবাহ।'],
      ['Keep ORS at home, and plan outdoor work for the early morning and evening.', 'ঘরে ওরস্যালাইন রাখুন, বাইরের কাজ ভোরে ও বিকেলে করার পরিকল্পনা করুন।'],
      ['Check on older people, babies, pregnant women and people with heart, kidney or diabetes problems every day.', 'বয়স্ক, শিশু, গর্ভবতী নারী এবং হৃদরোগ, কিডনি বা ডায়াবেটিসের রোগীদের প্রতিদিন খোঁজ নিন।'],
    ),
    doNow: lines(
      ['Drink water often, even if you are not thirsty. If you sweat a lot, drink ORS.', 'পিপাসা না লাগলেও বারবার পানি পান করুন। বেশি ঘামলে ওরস্যালাইন খান।'],
      ['Stay in the shade or indoors in the hottest hours, about 11 am to 4 pm.', 'সবচেয়ে গরমের সময়, মোটামুটি বেলা ১১টা থেকে বিকেল ৪টা, ছায়ায় বা ঘরে থাকুন।'],
      ['Wear loose, light-coloured cotton clothes and cover your head with a cap, umbrella or gamchha.', 'ঢিলেঢালা, হালকা রঙের সুতি কাপড় পরুন এবং টুপি, ছাতা বা গামছা দিয়ে মাথা ঢাকুন।'],
      ['Cool the body with a wet cloth or a bath.', 'ভেজা কাপড় দিয়ে শরীর মুছুন বা গোসল করুন।'],
      ['Rickshaw pullers, farmers and labourers: rest in the shade often.', 'রিকশাচালক, কৃষক ও শ্রমিক: বারবার ছায়ায় বিশ্রাম নিন।'],
    ),
    doNot: lines(
      ['Never leave a child or anyone in a closed car.', 'বন্ধ গাড়িতে কখনো শিশু বা কাউকে রেখে যাবেন না।'],
      ['Do not do heavy work in the sun at midday.', 'দুপুরে রোদে ভারী কাজ করবেন না।'],
      ['Do not rely on tea, coffee or soft drinks: drink water.', 'চা, কফি বা কোমল পানীয়ের ওপর নির্ভর করবেন না: পানি পান করুন।'],
      ['Do not eat stale food: food spoils fast in the heat.', 'বাসি খাবার খাবেন না: গরমে খাবার দ্রুত নষ্ট হয়।'],
    ),
    after: lines(
      ['Heat stroke is an emergency: very hot skin, confusion, fainting or fits. Call 999, move the person to the shade, pour water on the body and fan them, and put wet cloths on the neck, armpits and groin.', 'হিট স্ট্রোক জরুরি অবস্থা: শরীর খুব গরম, অসংলগ্ন কথা, অজ্ঞান হয়ে যাওয়া বা খিঁচুনি। ৯৯৯-এ কল করুন, ছায়ায় নিন, শরীরে পানি ঢেলে বাতাস করুন, এবং ঘাড়, বগল ও কুঁচকিতে ভেজা কাপড় দিন।'],
      ['Give water only if the person is fully awake and can swallow.', 'পুরোপুরি সজাগ থাকলে এবং গিলতে পারলে তবেই পানি দিন।'],
    ),
    getHelp: lines(
      ['Heat stroke (see above): call 999 at once.', 'হিট স্ট্রোক (ওপরে দেখুন): সঙ্গে সঙ্গে ৯৯৯-এ কল করুন।'],
      ['Heavy sweating, weakness, headache, dizziness or vomiting that is not better after an hour of rest and ORS in a cool place.', 'বেশি ঘাম, দুর্বলতা, মাথাব্যথা, মাথা ঘোরা বা বমি, যা ঠান্ডা জায়গায় এক ঘণ্টা বিশ্রাম ও ওরস্যালাইনেও না কমে।'],
    ),
    whoToContact: L('999 for an ambulance. 16263 (Shastho Batayon) for medical advice.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। চিকিৎসা পরামর্শের জন্য ১৬২৬৩ (স্বাস্থ্য বাতায়ন)।'),
    callNumbers: ['999', '16263'], sources: [BMD, WHO_HEAT, IFRC],
  },
  {
    id: 'coldwave', kind: 'disaster', icon: 'cold', title: L('Cold wave', 'শৈত্যপ্রবাহ'),
    prepare: lines(
      ['BMD calls 8–10°C a mild, 6–8°C a moderate, 4–6°C a severe and below 4°C a very severe cold wave. The northern districts are hit hardest.', 'আবহাওয়া অধিদপ্তরের হিসাবে ৮–১০° সেলসিয়াস মৃদু, ৬–৮° মাঝারি, ৪–৬° তীব্র এবং ৪°-এর নিচে অতি তীব্র শৈত্যপ্রবাহ। উত্তরের জেলাগুলোতে সবচেয়ে বেশি পড়ে।'],
      ['Keep warm clothes, blankets, caps and socks ready, especially for babies and older people.', 'গরম কাপড়, কম্বল, টুপি ও মোজা প্রস্তুত রাখুন, বিশেষ করে শিশু ও বয়স্কদের জন্য।'],
    ),
    doNow: lines(
      ['Wear several layers and cover the head, ears, hands and feet.', 'কয়েক স্তরে কাপড় পরুন এবং মাথা, কান, হাত ও পা ঢেকে রাখুন।'],
      ['Keep babies wrapped and close to the mother\'s body (skin to skin).', 'শিশুকে মুড়িয়ে মায়ের শরীরের সঙ্গে লাগিয়ে রাখুন (ত্বকের সঙ্গে ত্বক)।'],
      ['Eat warm food and drink warm water.', 'গরম খাবার খান ও গরম পানি পান করুন।'],
      ['Keep older people, babies and the sick indoors in the early morning and at night.', 'ভোরে ও রাতে বয়স্ক, শিশু ও অসুস্থদের ঘরের ভেতরে রাখুন।'],
      ['In fog, drive slowly with the headlights on.', 'কুয়াশায় হেডলাইট জ্বালিয়ে ধীরে গাড়ি চালান।'],
    ),
    doNot: lines(
      ['Do not burn charcoal, wood or a gas stove in a closed room for warmth: the gas (carbon monoxide) can kill while you sleep. Keep a window open.', 'ঘর গরম রাখতে বন্ধ ঘরে কয়লা, কাঠ বা গ্যাসের চুলা জ্বালাবেন না: এর গ্যাসে (কার্বন মনোক্সাইড) ঘুমের মধ্যে মৃত্যু হতে পারে। জানালা খোলা রাখুন।'],
      ['Do not sit close to an open fire in a loose sari, orna or shawl: winter fire burns are common.', 'ঢিলেঢালা শাড়ি, ওড়না বা চাদর পরে খোলা আগুনের খুব কাছে বসবেন না: শীতে আগুনে পোড়ার ঘটনা অনেক।'],
      ['Do not leave babies in wet clothes or bathe them in cold water.', 'শিশুকে ভেজা কাপড়ে রাখবেন না বা ঠান্ডা পানিতে গোসল করাবেন না।'],
    ),
    after: lines(
      ['For a burn: cool it under clean running water for 20 minutes, then cover it with a clean cloth.', 'আগুনে পুড়ে গেলে: পোড়া জায়গায় ২০ মিনিট পরিষ্কার প্রবাহিত পানি ঢালুন, তারপর পরিষ্কার কাপড়ে ঢেকে দিন।'],
    ),
    getHelp: lines(
      ['A baby or older person who is very cold, very sleepy, breathing fast or not feeding: go to the health complex at once.', 'শিশু বা বয়স্ক কেউ খুব ঠান্ডা হয়ে গেলে, বেশি ঘুমঘুম ভাব, দ্রুত শ্বাস নিলে বা খেতে না পারলে: সঙ্গে সঙ্গে স্বাস্থ্য কমপ্লেক্সে নিন।'],
      ['A child breathing fast or with the chest pulling in: it may be pneumonia. See a doctor today.', 'শিশুর দ্রুত শ্বাস বা বুকের নিচের অংশ দেবে যাওয়া নিউমোনিয়ার লক্ষণ হতে পারে। আজই ডাক্তার দেখান।'],
      ['Any large burn, or a burn on the face, hands or genitals.', 'বড় জায়গা পুড়ে গেলে, অথবা মুখ, হাত বা যৌনাঙ্গ পুড়লে।'],
    ),
    whoToContact: L('999 for an ambulance. 16263 (Shastho Batayon) for medical advice.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। চিকিৎসা পরামর্শের জন্য ১৬২৬৩ (স্বাস্থ্য বাতায়ন)।'),
    callNumbers: ['999', '16263'], sources: [BMD, IFRC, SOD],
  },
].map((g) => ({ ...g, reviewStatus: 'draft' }));

const file = 'apps/mobile/assets/seed/guides.json';
const seed = JSON.parse(fs.readFileSync(file, 'utf8'));
for (const g of disasterGuides) {
  const i = seed.guides.findIndex((x) => x.id === g.id);
  if (i >= 0) seed.guides[i] = g; else seed.guides.push(g);
}
const now = new Date();
seed.contentVersion = `${now.toISOString().slice(0, 10)}.1`;
fs.writeFileSync(file, JSON.stringify(seed, null, 2) + '\n');
console.log('guides.json:', seed.guides.length, 'guides,', disasterGuides.length, 'disaster guides written');

if (process.argv.includes('--publish')) {
  const { commit, publishSnapshots, listAll } = await import('../lib/firestore.mjs');
  // Only the guides written here: edits made on the admin website to other guides stay.
  const writes = disasterGuides.map((g) => ({ set: [`guides/${g.id}`, { ...g, published: true }] }));
  await commit(writes);
  const all = (await listAll('guides')).filter((g) => g.published);
  await publishSnapshots({ guides: all });
  console.log('published', all.length, 'guides to Firestore');
}
