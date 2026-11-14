// The first-aid guides that were still empty ("pending"). Written from the
// IFRC International First Aid, Resuscitation and Education Guidelines
// 2020 and WHO guidance, in plain Bangla and English. Status "draft": the
// app shows them with a "not yet checked by a doctor" banner until a
// clinician approves them on the admin website.
//
//   node tools/guides/first_aid_guides.mjs            → apps/mobile/assets/seed/guides.json
//   node tools/guides/first_aid_guides.mjs --publish  → also Firestore (every phone)
import fs from 'node:fs';

const IFRC = 'https://www.ifrc.org/document/international-first-aid-resuscitation-and-education-guidelines';
const WHO_DROWN = 'https://www.who.int/news-room/fact-sheets/detail/drowning';
const WHO_RABIES = 'https://www.who.int/news-room/fact-sheets/detail/rabies';
const WHO_POISON = 'https://www.who.int/news-room/fact-sheets/detail/suicide';
const FSCD = 'https://fireservice.gov.bd';

const L = (en, bn) => ({ en, bn });
const lines = (...pairs) => ({ en: pairs.map((p) => p[0]), bn: pairs.map((p) => p[1]) });

export const firstAidGuides = [
  {
    id: 'heart-emergency', icon: 'heart', title: L('Heart attack and chest pain', 'হার্ট অ্যাটাক ও বুকে ব্যথা'),
    doNow: lines(
      ['Call 999 at once if chest pain or pressure lasts more than a few minutes, or spreads to the arm, jaw, neck or back, with sweating, breathlessness or vomiting.', 'বুকে ব্যথা বা চাপ কয়েক মিনিটের বেশি থাকলে, অথবা হাত, চোয়াল, ঘাড় বা পিঠে ছড়ালে এবং সঙ্গে ঘাম, শ্বাসকষ্ট বা বমি হলে সঙ্গে সঙ্গে ৯৯৯-এ কল করুন।'],
      ['Help them sit and rest, half lying with knees bent, and loosen tight clothes.', 'আধশোয়া অবস্থায় হাঁটু ভাঁজ করে বসিয়ে বিশ্রাম নিতে দিন, আঁটসাঁট কাপড় ঢিলা করে দিন।'],
      ['If they are an adult and not allergic to aspirin, give one 300 mg aspirin to chew. If they have their own heart medicine (spray or tablet under the tongue), help them take it.', 'প্রাপ্তবয়স্ক হলে এবং অ্যাসপিরিনে অ্যালার্জি না থাকলে একটি ৩০০ মিলিগ্রাম অ্যাসপিরিন চিবিয়ে খেতে দিন। নিজের হৃদরোগের ওষুধ (স্প্রে বা জিভের নিচের ট্যাবলেট) থাকলে তা নিতে সাহায্য করুন।'],
      ['Stay with them, keep them calm and watch their breathing.', 'পাশে থাকুন, শান্ত রাখুন এবং শ্বাস-প্রশ্বাস খেয়াল করুন।'],
      ['If they stop responding and do not breathe normally, start CPR: push hard and fast in the centre of the chest, 100 to 120 times a minute, until help arrives.', 'সাড়া না দিলে ও স্বাভাবিকভাবে শ্বাস না নিলে সিপিআর শুরু করুন: বুকের মাঝখানে জোরে ও দ্রুত চাপ দিন, মিনিটে ১০০ থেকে ১২০ বার, সাহায্য না আসা পর্যন্ত।'],
    ),
    doNot: lines(
      ['Do not let them walk or carry anything.', 'হাঁটতে বা কিছু বহন করতে দেবেন না।'],
      ['Do not give aspirin to a child or to anyone allergic to it.', 'শিশুকে বা অ্যাসপিরিনে অ্যালার্জি আছে এমন কাউকে অ্যাসপিরিন দেবেন না।'],
      ['Do not wait to see if the pain goes away.', 'ব্যথা কমে কি না দেখার জন্য অপেক্ষা করবেন না।'],
    ),
    getHelp: lines(
      ['Chest pain like this always needs a hospital with an emergency department, even if the pain eases.', 'এ ধরনের বুকে ব্যথায় সব সময় জরুরি বিভাগ আছে এমন হাসপাতালে যেতে হবে, ব্যথা কমে গেলেও।'],
    ),
    whoToContact: L('999 for an ambulance. Go to the nearest hospital with an emergency department.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। জরুরি বিভাগ আছে এমন কাছের হাসপাতালে যান।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'stroke', icon: 'stroke', title: L('Stroke', 'স্ট্রোক'),
    doNow: lines(
      ['Check FAST. Face: does one side droop? Arms: can they lift both? Speech: is it slurred or strange? Time: call 999 now.', 'FAST দেখুন। মুখ: এক পাশ বেঁকে গেছে? হাত: দুই হাত তুলতে পারছেন? কথা: জড়িয়ে যাচ্ছে বা অসংলগ্ন? সময়: এখনই ৯৯৯-এ কল করুন।'],
      ['Note the time the signs started. Doctors need it to choose the treatment.', 'লক্ষণ কখন শুরু হয়েছে সেই সময় লিখে রাখুন। চিকিৎসা ঠিক করতে ডাক্তারের এটি দরকার।'],
      ['Take them as fast as possible to a hospital that can do a CT scan (district or medical college hospital).', 'যত দ্রুত সম্ভব সিটি স্ক্যান করা যায় এমন হাসপাতালে (জেলা বা মেডিকেল কলেজ হাসপাতাল) নিয়ে যান।'],
      ['If they are drowsy or vomiting, lay them on their side with the head a little raised.', 'ঘুমঘুম ভাব বা বমি হলে মাথা একটু উঁচু করে কাত করে শুইয়ে দিন।'],
    ),
    doNot: lines(
      ['Do not give food, water or medicine, not even aspirin: they may choke, and some strokes are bleeding in the brain.', 'খাবার, পানি বা কোনো ওষুধ দেবেন না, অ্যাসপিরিনও না: গলায় আটকে যেতে পারে, আর কিছু স্ট্রোকে মস্তিষ্কে রক্তক্ষরণ হয়।'],
      ['Do not wait for the signs to pass. Even signs that go away need a doctor today.', 'লক্ষণ চলে যাওয়ার অপেক্ষা করবেন না। লক্ষণ চলে গেলেও আজই ডাক্তার দেখাতে হবে।'],
    ),
    getHelp: lines(
      ['Always, at once: stroke treatment works best in the first few hours.', 'সব সময়, সঙ্গে সঙ্গে: প্রথম কয়েক ঘণ্টায় চিকিৎসা সবচেয়ে বেশি কাজ করে।'],
    ),
    whoToContact: L('999 for an ambulance.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'unconscious', icon: 'unconscious', title: L('Unconscious person and CPR', 'অজ্ঞান ব্যক্তি ও সিপিআর'),
    doNow: lines(
      ['Make sure it is safe, then tap their shoulders and shout. If there is no answer, call 999 (put the phone on speaker).', 'জায়গাটি নিরাপদ কি না দেখুন, তারপর কাঁধে টোকা দিয়ে জোরে ডাকুন। সাড়া না দিলে ৯৯৯-এ কল করুন (ফোন স্পিকারে রাখুন)।'],
      ['Tilt the head back and lift the chin. Look at the chest for up to 10 seconds: is it rising normally?', 'মাথা পেছনে হেলিয়ে থুতনি উঁচু করুন। সর্বোচ্চ ১০ সেকেন্ড বুকের দিকে দেখুন: স্বাভাবিকভাবে ওঠানামা করছে?'],
      ['Breathing normally: roll them onto their side (recovery position) so they cannot choke, and keep checking.', 'স্বাভাবিক শ্বাস নিলে: কাত করে শুইয়ে দিন (রিকভারি পজিশন) যাতে গলায় কিছু আটকে না যায়, এবং বারবার দেখুন।'],
      ['Not breathing normally: start CPR. Push hard and fast in the centre of the chest, 5–6 cm deep, 100–120 times a minute. If trained, give 2 breaths after every 30 pushes.', 'স্বাভাবিক শ্বাস না নিলে: সিপিআর শুরু করুন। বুকের মাঝখানে ৫–৬ সেমি গভীর করে জোরে ও দ্রুত চাপ দিন, মিনিটে ১০০–১২০ বার। প্রশিক্ষণ থাকলে প্রতি ৩০ চাপের পর ২ বার মুখে শ্বাস দিন।'],
      ['Do not stop until help arrives or they start breathing. Take turns with someone if you get tired.', 'সাহায্য না আসা বা শ্বাস না ফেরা পর্যন্ত থামবেন না। ক্লান্ত হলে অন্য কারো সঙ্গে পালা করুন।'],
    ),
    doNot: lines(
      ['Do not give anything to eat or drink.', 'কিছু খেতে বা পান করতে দেবেন না।'],
      ['Do not leave a breathing person lying on their back: they can choke on vomit.', 'শ্বাস নিচ্ছেন এমন ব্যক্তিকে চিত করে ফেলে রাখবেন না: বমিতে শ্বাস আটকে যেতে পারে।'],
      ['Do not hold a shoe or onion to the nose or pour water on the face. It does not help and wastes time.', 'নাকে জুতা বা পেঁয়াজ ধরবেন না, মুখে পানি ঢালবেন না। এতে কোনো লাভ হয় না, শুধু সময় নষ্ট হয়।'],
    ),
    getHelp: lines(
      ['Anyone who has been unconscious, even for a short time, must see a doctor.', 'অল্প সময়ের জন্য হলেও অজ্ঞান হয়ে থাকলে ডাক্তার দেখাতে হবে।'],
    ),
    whoToContact: L('999 for an ambulance. The operator can guide you through CPR.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। অপারেটর আপনাকে সিপিআর দিতে নির্দেশনা দিতে পারেন।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'fracture', icon: 'fracture', title: L('Broken bone (fracture)', 'হাড় ভাঙা'),
    doNow: lines(
      ['Keep the injured part still, in the position you found it.', 'আঘাত পাওয়া অংশটি যেমন আছে তেমনভাবে স্থির রাখুন।'],
      ['Support it with a padded splint (a rolled newspaper, a stick or a board wrapped in cloth), tied above and below the injury, not on it.', 'কাপড়ে মোড়ানো শক্ত কিছু দিয়ে (গোল করে পাকানো খবরের কাগজ, লাঠি বা কাঠ) স্প্লিন্ট দিন; ভাঙা জায়গার ওপরে ও নিচে বাঁধুন, ঠিক ভাঙা জায়গায় নয়।'],
      ['For an arm, make a sling from a scarf or orna.', 'হাত ভাঙলে ওড়না বা গামছা দিয়ে গলায় ঝুলিয়ে দিন (স্লিং)।'],
      ['If bone comes through the skin, cover the wound with a clean cloth and press around it, not on the bone, to stop bleeding.', 'হাড় চামড়া ভেদ করে বেরিয়ে এলে পরিষ্কার কাপড়ে ঢেকে দিন এবং রক্ত থামাতে হাড়ের ওপর নয়, চারপাশে চাপ দিন।'],
      ['Put ice or a cold pack wrapped in cloth on it for up to 20 minutes.', 'কাপড়ে মোড়ানো বরফ সর্বোচ্চ ২০ মিনিট লাগিয়ে রাখুন।'],
    ),
    doNot: lines(
      ['Do not try to straighten the bone or push it back in.', 'হাড় সোজা করার বা ভেতরে ঢোকানোর চেষ্টা করবেন না।'],
      ['Do not go to a traditional bone setter: tight bandages can cut off the blood and cause loss of the limb.', 'হাড়জোড়া কবিরাজের কাছে যাবেন না: শক্ত করে বাঁধার ফলে রক্ত চলাচল বন্ধ হয়ে হাত-পা হারাতে হতে পারে।'],
      ['Do not move someone with a possible neck or back injury unless they are in danger.', 'ঘাড় বা মেরুদণ্ডে আঘাতের সম্ভাবনা থাকলে বিপদ না থাকলে নাড়াবেন না।'],
    ),
    getHelp: lines(
      ['Every possible fracture needs an X-ray.', 'হাড় ভাঙার সন্দেহ হলেই এক্স-রে করাতে হবে।'],
      ['Call 999 if the limb is cold, blue or numb, bone is through the skin, or the head, neck, back, hip or thigh is injured.', 'হাত-পা ঠান্ডা, নীল বা অবশ হলে, হাড় বেরিয়ে এলে, অথবা মাথা, ঘাড়, পিঠ, কোমর বা উরুতে আঘাত হলে ৯৯৯-এ কল করুন।'],
    ),
    whoToContact: L('999 for an ambulance, or go to a hospital with an orthopaedic department.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯, অথবা অর্থোপেডিক বিভাগ আছে এমন হাসপাতালে যান।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'drowning', icon: 'drowning', title: L('Drowning', 'পানিতে ডোবা'),
    doNow: lines(
      ['Shout for help. Reach or throw, do not go in: hold out a stick, rope or gamchha, or throw something that floats (an empty jerrycan, a bunch of bottles).', 'চিৎকার করে সাহায্য ডাকুন। নিজে পানিতে না নেমে লাঠি, দড়ি বা গামছা বাড়িয়ে দিন, অথবা ভেসে থাকে এমন কিছু ছুড়ে দিন (খালি জেরিক্যান, কয়েকটি বোতল একসঙ্গে)।'],
      ['Once out of the water, check breathing. If they are not breathing, give 5 rescue breaths if you are trained, then start CPR (30 pushes, 2 breaths).', 'পানি থেকে তোলার পর শ্বাস দেখুন। শ্বাস না নিলে প্রশিক্ষণ থাকলে প্রথমে ৫ বার মুখে শ্বাস দিন, তারপর সিপিআর শুরু করুন (৩০ বার চাপ, ২ বার শ্বাস)।'],
      ['If they are breathing, lay them on their side and keep them warm with dry cloth.', 'শ্বাস নিলে কাত করে শুইয়ে দিন এবং শুকনো কাপড়ে মুড়ে উষ্ণ রাখুন।'],
      ['Call 999 or take them to hospital, even if they seem fine.', 'ভালো দেখালেও ৯৯৯-এ কল করুন বা হাসপাতালে নিন।'],
    ),
    doNot: lines(
      ['Do not spin a child over your head or lay them on a cooking pot to get the water out. It wastes the minutes that matter: start breathing for them.', 'পানি বের করার জন্য শিশুকে মাথার ওপর ঘোরাবেন না বা হাঁড়ির ওপর উপুড় করে রাখবেন না। এতে জরুরি সময় নষ্ট হয়: শ্বাস দেওয়া শুরু করুন।'],
      ['Do not press on the stomach to push water out.', 'পানি বের করতে পেটে চাপ দেবেন না।'],
      ['Do not jump in to rescue unless you are trained and it is safe.', 'প্রশিক্ষণ না থাকলে ও নিরাপদ না হলে উদ্ধার করতে পানিতে লাফ দেবেন না।'],
    ),
    getHelp: lines(
      ['Always go to hospital: breathing problems can start hours later.', 'সব সময় হাসপাতালে নিন: কয়েক ঘণ্টা পরেও শ্বাসকষ্ট শুরু হতে পারে।'],
      ['Drowning is the biggest killer of children aged 1 to 4 in Bangladesh: always keep small children within arm\'s reach near ponds, and fence or cover water.', 'বাংলাদেশে ১ থেকে ৪ বছরের শিশুমৃত্যুর প্রধান কারণ পানিতে ডোবা: পুকুরের কাছে ছোট শিশুকে সব সময় হাতের নাগালে রাখুন, পুকুরে বেড়া দিন বা পানির পাত্র ঢেকে রাখুন।'],
    ),
    whoToContact: L('999 for an ambulance.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯।'),
    callNumbers: ['999'], sources: [IFRC, WHO_DROWN],
  },
  {
    id: 'animal-bite', icon: 'animal', title: L('Dog, cat and animal bites (rabies)', 'কুকুর, বিড়াল ও প্রাণীর কামড় (জলাতঙ্ক)'),
    doNow: lines(
      ['Wash the bite at once with soap and plenty of running water for 15 minutes. This greatly lowers the risk of rabies.', 'কামড়ের জায়গা সঙ্গে সঙ্গে সাবান ও প্রচুর প্রবাহিত পানি দিয়ে ১৫ মিনিট ধরে ধুয়ে ফেলুন। এতে জলাতঙ্কের ঝুঁকি অনেক কমে।'],
      ['Then put on an antiseptic (povidone-iodine) if you have it, and cover with a clean cloth. Press to stop bleeding.', 'তারপর থাকলে জীবাণুনাশক (পোভিডন-আয়োডিন) লাগান এবং পরিষ্কার কাপড়ে ঢেকে দিন। রক্ত পড়লে চেপে ধরুন।'],
      ['Go the same day to a government hospital for the rabies vaccine (free) and a tetanus injection.', 'সেদিনই সরকারি হাসপাতালে গিয়ে জলাতঙ্কের টিকা (বিনামূল্যে) ও টিটেনাসের ইনজেকশন নিন।'],
    ),
    doNot: lines(
      ['Do not put chilli, turmeric, lime (chun), oil or herbs on the wound.', 'ক্ষতে মরিচ, হলুদ, চুন, তেল বা লতাপাতা লাগাবেন না।'],
      ['Do not wait for signs of illness: once rabies starts it cannot be cured.', 'অসুস্থতার লক্ষণের অপেক্ষা করবেন না: জলাতঙ্ক একবার শুরু হলে আর সারানো যায় না।'],
      ['Do not rely on a kobiraj or jhar-phuk instead of the vaccine.', 'টিকার বদলে কবিরাজ বা ঝাড়ফুঁকের ওপর ভরসা করবেন না।'],
    ),
    getHelp: lines(
      ['Every bite or scratch that broke the skin from a dog, cat, monkey, jackal or mongoose needs the rabies vaccine.', 'কুকুর, বিড়াল, বানর, শিয়াল বা বেজির কামড় বা আঁচড়ে চামড়া কেটে গেলেই জলাতঙ্কের টিকা নিতে হবে।'],
      ['Deep bites, heavy bleeding, or bites on the face, head or hands: hospital at once.', 'গভীর কামড়, বেশি রক্তপাত, অথবা মুখ, মাথা বা হাতে কামড়: সঙ্গে সঙ্গে হাসপাতালে যান।'],
    ),
    whoToContact: L('16263 (Shastho Batayon) to find the nearest vaccine centre. 999 for heavy bleeding.', 'কাছের টিকাকেন্দ্র জানতে ১৬২৬৩ (স্বাস্থ্য বাতায়ন)। বেশি রক্তপাতে ৯৯৯।'),
    callNumbers: ['16263', '999'], sources: [WHO_RABIES, IFRC],
  },
  {
    id: 'poisoning', icon: 'poison', title: L('Poisoning (pesticide, medicine, kerosene)', 'বিষক্রিয়া (কীটনাশক, ওষুধ, কেরোসিন)'),
    doNow: lines(
      ['Call 999 or go to the nearest hospital at once. Take the bottle, packet or plant with you.', 'সঙ্গে সঙ্গে ৯৯৯-এ কল করুন বা কাছের হাসপাতালে যান। বোতল, প্যাকেট বা গাছটি সঙ্গে নিয়ে যান।'],
      ['On the skin: take off the clothes and wash the skin with soap and lots of water for 15 minutes. Protect your own hands with gloves or plastic.', 'চামড়ায় লাগলে: কাপড় খুলে সাবান ও প্রচুর পানি দিয়ে ১৫ মিনিট ধুয়ে দিন। নিজের হাত গ্লাভস বা পলিথিনে ঢেকে নিন।'],
      ['In the eyes: rinse with clean running water for 15 minutes.', 'চোখে গেলে: পরিষ্কার প্রবাহিত পানি দিয়ে ১৫ মিনিট ধুয়ে দিন।'],
      ['Gas or fumes: move the person into fresh air.', 'গ্যাস বা ধোঁয়া হলে: খোলা বাতাসে নিয়ে যান।'],
      ['Unconscious but breathing: lay them on their side. Not breathing: start CPR with chest pushes only.', 'অজ্ঞান কিন্তু শ্বাস নিচ্ছেন: কাত করে শুইয়ে দিন। শ্বাস না নিলে: শুধু বুকে চাপ দিয়ে সিপিআর দিন।'],
    ),
    doNot: lines(
      ['Do not make them vomit: no salt water, soap water or fingers in the throat.', 'বমি করাবেন না: লবণ-পানি, সাবান-পানি দেবেন না বা গলায় আঙুল দেবেন না।'],
      ['Do not give milk, oil or anything else by mouth unless a doctor says so.', 'ডাক্তার না বললে দুধ, তেল বা অন্য কিছু খাওয়াবেন না।'],
      ['Do not wait for signs: some poisons act after hours.', 'লক্ষণের অপেক্ষা করবেন না: কিছু বিষ কয়েক ঘণ্টা পরে কাজ করে।'],
    ),
    getHelp: lines(
      ['Always, for any swallowed pesticide, rat poison, kerosene, or too much medicine.', 'কীটনাশক, ইঁদুরের বিষ, কেরোসিন বা অতিরিক্ত ওষুধ খেলে সব সময়।'],
      ['If someone took poison on purpose, stay with them and get help now. Kaan Pete Roi (emotional support) can help afterwards.', 'কেউ ইচ্ছা করে বিষ খেলে তাঁর পাশে থাকুন এবং এখনই সাহায্য নিন। পরে মানসিক সহায়তার জন্য "কান পেতে রই" সাহায্য করতে পারে।'],
    ),
    whoToContact: L('999 for an ambulance. 16263 (Shastho Batayon) for medical advice.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯। চিকিৎসা পরামর্শের জন্য ১৬২৬৩ (স্বাস্থ্য বাতায়ন)।'),
    callNumbers: ['999', '16263'], sources: [IFRC, WHO_POISON],
  },
  {
    id: 'seizure', icon: 'seizure', title: L('Seizure (fits)', 'খিঁচুনি'),
    doNow: lines(
      ['Stay calm and note the time the fit started.', 'শান্ত থাকুন এবং খিঁচুনি শুরুর সময় খেয়াল করুন।'],
      ['Move hard or sharp things away and put something soft under the head.', 'শক্ত বা ধারালো জিনিস সরিয়ে দিন, মাথার নিচে নরম কিছু দিন।'],
      ['Loosen tight clothes around the neck.', 'গলার কাছের আঁটসাঁট কাপড় ঢিলা করে দিন।'],
      ['When the jerking stops, roll them onto their side and stay until they are fully awake.', 'ঝাঁকুনি থামলে কাত করে শুইয়ে দিন এবং পুরোপুরি সজাগ না হওয়া পর্যন্ত পাশে থাকুন।'],
      ['Call 999 if it lasts more than 5 minutes, another fit follows, it is their first fit, they are hurt or pregnant, or it happened in water.', 'খিঁচুনি ৫ মিনিটের বেশি থাকলে, পরপর আবার হলে, প্রথমবার হলে, আঘাত পেলে বা গর্ভবতী হলে, অথবা পানিতে হলে ৯৯৯-এ কল করুন।'],
    ),
    doNot: lines(
      ['Do not hold them down or try to stop the movements.', 'চেপে ধরবেন না বা নড়াচড়া থামানোর চেষ্টা করবেন না।'],
      ['Do not put anything in the mouth, not a spoon and not your fingers. They cannot swallow their tongue.', 'মুখে কিছু ঢোকাবেন না, চামচ বা আঙুলও না। জিভ গিলে ফেলার কোনো ভয় নেই।'],
      ['Do not hold a shoe or onion to the nose, or pour water on them.', 'নাকে জুতা বা পেঁয়াজ ধরবেন না, গায়ে পানি ঢালবেন না।'],
      ['Do not give food or drink until they are fully awake.', 'পুরোপুরি সজাগ না হওয়া পর্যন্ত খাবার বা পানি দেবেন না।'],
    ),
    getHelp: lines(
      ['A first seizure, a fit with high fever in a child, or trouble breathing afterwards: see a doctor today.', 'প্রথমবার খিঁচুনি, শিশুর জ্বরের সঙ্গে খিঁচুনি, বা পরে শ্বাসকষ্ট: আজই ডাক্তার দেখান।'],
    ),
    whoToContact: L('999 for an ambulance.', 'অ্যাম্বুলেন্সের জন্য ৯৯৯।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'road-accident', icon: 'road', title: L('Road accident', 'সড়ক দুর্ঘটনা'),
    doNow: lines(
      ['Make the place safe: warn traffic, switch off engines, and do not smoke.', 'জায়গাটি নিরাপদ করুন: অন্য গাড়িকে সতর্ক করুন, ইঞ্জিন বন্ধ করুন, ধূমপান করবেন না।'],
      ['Call 999: say exactly where, how many are hurt, and if anyone is trapped. The Road accident button in this app shares your location.', '৯৯৯-এ কল করুন: ঠিক কোথায়, কতজন আহত এবং কেউ আটকে আছে কি না জানান। এই অ্যাপের "সড়ক দুর্ঘটনা" বোতাম আপনার লোকেশন পাঠায়।'],
      ['Help first anyone who is not breathing or is bleeding heavily. Press hard on bleeding with a cloth.', 'যিনি শ্বাস নিচ্ছেন না বা যাঁর বেশি রক্ত পড়ছে, তাঁকে আগে সাহায্য করুন। রক্তপাতের জায়গায় কাপড় দিয়ে জোরে চেপে ধরুন।'],
      ['Keep injured people still, especially with neck or back pain. Support the head with your hands.', 'আহতদের স্থির রাখুন, বিশেষ করে ঘাড় বা পিঠে ব্যথা থাকলে। হাত দিয়ে মাথা ধরে রাখুন।'],
      ['If someone is unconscious and breathing, keep the airway open; roll them on their side only if needed, keeping head, neck and back in a line.', 'কেউ অজ্ঞান কিন্তু শ্বাস নিলে শ্বাসনালি খোলা রাখুন; দরকার হলে তবেই কাত করুন, মাথা-ঘাড়-পিঠ এক সরলরেখায় রেখে।'],
    ),
    doNot: lines(
      ['Do not pull people out of a vehicle unless there is fire or another danger.', 'আগুন বা অন্য বিপদ না থাকলে গাড়ি থেকে টেনে বের করবেন না।'],
      ['Do not take off a motorcyclist\'s helmet unless they are not breathing or are vomiting.', 'শ্বাস না নিলে বা বমি না করলে মোটরসাইকেল আরোহীর হেলমেট খুলবেন না।'],
      ['Do not carry the injured folded up in a rickshaw or CNG if an ambulance can come.', 'অ্যাম্বুলেন্স আসতে পারলে আহতকে ভাঁজ করে রিকশা বা সিএনজিতে নেবেন না।'],
      ['Do not give water or food.', 'পানি বা খাবার দেবেন না।'],
    ),
    getHelp: lines(
      ['Everyone in a serious crash should be checked in hospital.', 'বড় দুর্ঘটনায় পড়া সবাইকে হাসপাতালে পরীক্ষা করাতে হবে।'],
      ['After a head injury: vomiting, drowsiness, confusion or a bad headache, even hours later, need hospital at once.', 'মাথায় আঘাতের পর বমি, ঘুমঘুম ভাব, অসংলগ্ন কথা বা তীব্র মাথাব্যথা হলে, কয়েক ঘণ্টা পরে হলেও, সঙ্গে সঙ্গে হাসপাতালে নিন।'],
    ),
    whoToContact: L('999 for ambulance, police and Fire Service.', 'অ্যাম্বুলেন্স, পুলিশ ও ফায়ার সার্ভিসের জন্য ৯৯৯।'),
    callNumbers: ['999'], sources: [IFRC],
  },
  {
    id: 'fire', icon: 'fire', title: L('Fire in a building', 'ভবনে আগুন'),
    doNow: lines(
      ['Shout "Fire!" to warn everyone, and call 999 (Fire Service: 102).', '"আগুন!" বলে চিৎকার করে সবাইকে সতর্ক করুন এবং ৯৯৯-এ কল করুন (ফায়ার সার্ভিস: ১০২)।'],
      ['Leave at once by the stairs, and close doors behind you to slow the fire.', 'সঙ্গে সঙ্গে সিঁড়ি দিয়ে বের হোন, এবং আগুন ছড়ানো ধীর করতে পেছনের দরজা বন্ধ করে দিন।'],
      ['In smoke, crawl low and cover your nose and mouth with a wet cloth.', 'ধোঁয়ার মধ্যে মাথা নিচু করে হামাগুড়ি দিয়ে চলুন, ভেজা কাপড়ে নাক-মুখ ঢাকুন।'],
      ['Touch a door with the back of your hand before opening it. If it is hot, use another way out.', 'দরজা খোলার আগে হাতের উল্টো পিঠ দিয়ে ছুঁয়ে দেখুন। গরম হলে অন্য পথ ধরুন।'],
      ['If your clothes catch fire: stop, drop to the ground and roll, covering your face.', 'কাপড়ে আগুন লাগলে: থামুন, মাটিতে শুয়ে পড়ুন এবং মুখ ঢেকে গড়াগড়ি দিন।'],
      ['Trapped: close the door, block gaps with wet cloth, go to a window and signal for help.', 'আটকে পড়লে: দরজা বন্ধ করুন, ফাঁক ভেজা কাপড়ে বন্ধ করুন, জানালার কাছে গিয়ে সাহায্যের সংকেত দিন।'],
    ),
    doNot: lines(
      ['Do not use the lift.', 'লিফট ব্যবহার করবেন না।'],
      ['Do not go back inside for belongings.', 'জিনিসপত্র আনতে ভেতরে ফিরে যাবেন না।'],
      ['Do not throw water on a cooking-oil or electrical fire: cover the pan with a lid or wet sack, and switch off the gas and electricity.', 'রান্নার তেল বা বৈদ্যুতিক আগুনে পানি ঢালবেন না: ঢাকনা বা ভেজা চট দিয়ে কড়াই ঢেকে দিন, গ্যাস ও বিদ্যুৎ বন্ধ করুন।'],
      ['Do not jump from an upper floor unless there is no other way.', 'অন্য কোনো উপায় না থাকলে ওপরতলা থেকে লাফ দেবেন না।'],
    ),
    getHelp: lines(
      ['Anyone who breathed smoke (cough, hoarse voice, trouble breathing) or has burns must go to hospital.', 'যিনি ধোঁয়া টেনেছেন (কাশি, গলা বসে যাওয়া, শ্বাসকষ্ট) বা পুড়ে গেছেন, তাঁকে হাসপাতালে নিতে হবে।'],
    ),
    whoToContact: L('999, or Fire Service 102.', '৯৯৯, অথবা ফায়ার সার্ভিস ১০২।'),
    callNumbers: ['999', '102'], sources: [FSCD, IFRC],
  },
  {
    id: 'gas-leak', icon: 'gas', title: L('Gas leak', 'গ্যাস লিক'),
    doNow: lines(
      ['If you smell gas, open all doors and windows at once.', 'গ্যাসের গন্ধ পেলে সঙ্গে সঙ্গে সব দরজা-জানালা খুলে দিন।'],
      ['Close the gas at the cylinder or the main valve if it is safe to reach.', 'নিরাপদে পৌঁছানো গেলে সিলিন্ডার বা মেইন ভালভ থেকে গ্যাস বন্ধ করুন।'],
      ['Get everyone out of the house or building.', 'সবাইকে ঘর বা ভবন থেকে বের করে আনুন।'],
      ['From outside, call 999 or your gas company\'s emergency line.', 'বাইরে থেকে ৯৯৯ বা আপনার গ্যাস কোম্পানির জরুরি নম্বরে কল করুন।'],
    ),
    doNot: lines(
      ['Do not light a match, lighter or stove, and do not smoke.', 'দেশলাই, লাইটার বা চুলা জ্বালাবেন না, ধূমপান করবেন না।'],
      ['Do not touch light switches, plugs or the doorbell: a spark can cause an explosion.', 'লাইটের সুইচ, প্লাগ বা কলিং বেলে হাত দেবেন না: একটি স্ফুলিঙ্গে বিস্ফোরণ হতে পারে।'],
      ['Do not look for the leak with a flame.', 'আগুন দিয়ে লিক খুঁজবেন না।'],
      ['Do not go back inside until the gas company or Fire Service says it is safe.', 'গ্যাস কোম্পানি বা ফায়ার সার্ভিস নিরাপদ না বলা পর্যন্ত ভেতরে ফিরবেন না।'],
    ),
    getHelp: lines(
      ['Headache, dizziness or vomiting after breathing gas: fresh air and a doctor.', 'গ্যাস নিঃশ্বাসে নেওয়ার পর মাথাব্যথা, মাথা ঘোরা বা বমি: খোলা বাতাস ও ডাক্তার।'],
      ['Unconscious: call 999, and start CPR if they are not breathing.', 'অজ্ঞান হলে: ৯৯৯-এ কল করুন, শ্বাস না নিলে সিপিআর শুরু করুন।'],
    ),
    whoToContact: L('999 or Fire Service 102. Your gas company\'s emergency line for the supply.', '৯৯৯ বা ফায়ার সার্ভিস ১০২। সংযোগের জন্য গ্যাস কোম্পানির জরুরি নম্বর।'),
    callNumbers: ['999', '102'], sources: [FSCD],
  },
  {
    id: 'building-collapse', icon: 'collapse', title: L('Building collapse', 'ভবন ধস'),
    doNow: lines(
      ['If you can, get out and move well away: more of the building may fall.', 'সম্ভব হলে বেরিয়ে অনেক দূরে সরে যান: ভবনের আরও অংশ ভেঙে পড়তে পারে।'],
      ['Call 999 and tell the Fire Service exactly where people may be trapped.', '৯৯৯-এ কল করে ফায়ার সার্ভিসকে জানান ঠিক কোথায় মানুষ আটকে থাকতে পারে।'],
      ['If you are trapped: cover your mouth with cloth, tap on a pipe or wall, use your phone light or a whistle. Shout only as a last resort.', 'আটকে পড়লে: কাপড়ে মুখ ঢাকুন, পাইপ বা দেয়ালে টোকা দিন, ফোনের আলো বা বাঁশি ব্যবহার করুন। একান্ত দরকার না হলে চিৎকার করবেন না।'],
      ['Helpers: free people only from loose rubble near the surface, and only if it is safe. Leave deeper rescue to the Fire Service.', 'উদ্ধারকারীরা: শুধু ওপরের আলগা ধ্বংসস্তূপ থেকে, এবং নিরাপদ হলে তবেই মানুষ বের করুন। গভীরের উদ্ধার ফায়ার সার্ভিসের ওপর ছেড়ে দিন।'],
    ),
    doNot: lines(
      ['Do not light a match or lighter: there may be a gas leak.', 'দেশলাই বা লাইটার জ্বালাবেন না: গ্যাস লিক থাকতে পারে।'],
      ['Do not go into a damaged building.', 'ক্ষতিগ্রস্ত ভবনে ঢুকবেন না।'],
      ['Do not pull a trapped person out roughly. Someone pressed under weight for a long time needs medical care as soon as they are freed.', 'আটকে পড়া মানুষকে জোর করে টেনে বের করবেন না। অনেকক্ষণ চাপা পড়ে থাকলে মুক্ত হওয়ার সঙ্গে সঙ্গে চিকিৎসা দরকার।'],
    ),
    getHelp: lines(
      ['Everyone rescued needs a hospital check, especially people trapped for a long time (crush injury can damage the kidneys).', 'উদ্ধার হওয়া সবাইকে হাসপাতালে দেখাতে হবে, বিশেষ করে যাঁরা অনেকক্ষণ চাপা পড়ে ছিলেন (চাপা পড়ার আঘাতে কিডনির ক্ষতি হতে পারে)।'],
    ),
    whoToContact: L('999, or Fire Service 102.', '৯৯৯, অথবা ফায়ার সার্ভিস ১০২।'),
    callNumbers: ['999', '102'], sources: [FSCD, IFRC],
  },
].map((g) => ({ ...g, kind: 'firstAid', reviewStatus: 'draft' }));

const file = 'apps/mobile/assets/seed/guides.json';
const seed = JSON.parse(fs.readFileSync(file, 'utf8'));
for (const g of firstAidGuides) {
  const i = seed.guides.findIndex((x) => x.id === g.id);
  if (i < 0) throw new Error('unknown guide ' + g.id);
  // Running again is fine; a guide someone else filled in is not overwritten.
  const same = JSON.stringify(seed.guides[i]) === JSON.stringify(g);
  if (seed.guides[i].reviewStatus !== 'pending' && !same) throw new Error(`${g.id} already has other content; not overwritten`);
  seed.guides[i] = g;
}
fs.writeFileSync(file, JSON.stringify(seed, null, 2) + '\n');
console.log('guides.json:', firstAidGuides.length, 'first-aid guides written');

if (process.argv.includes('--publish')) {
  const { commit, publishSnapshots, listAll } = await import('../lib/firestore.mjs');
  const live = Object.fromEntries((await listAll('guides')).map((g) => [g.id, g]));
  // Only guides still empty on the website: a guide edited there stays.
  const writes = firstAidGuides.filter((g) => !live[g.id] || live[g.id].reviewStatus === 'pending' || !live[g.id].doNow)
    .map((g) => ({ set: [`guides/${g.id}`, { ...g, published: true }] }));
  await commit(writes);
  const all = (await listAll('guides')).filter((g) => g.published);
  await publishSnapshots({ guides: all });
  console.log('published', writes.length, 'guides;', all.length, 'guides on phones');
}
