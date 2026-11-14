import '../localized_text.dart';
import 'cap_parser.dart';
import 'hazard_alert.dart';

/// One of the 11 storm warning signals hoisted at Bangladesh's sea ports
/// (Chattogram, Cox's Bazar, Mongla, Payra) by order of the Bangladesh
/// Meteorological Department, and what people on the coast should do.
class StormSignal {
  const StormSignal(this.number, this.name, this.meaning, this.whatToDo);

  final int number;
  final LocalizedText name;
  final LocalizedText meaning;
  final LocalizedText whatToDo;

  AlertLevel get level => levelForSignal(number);

  static StormSignal? of(int? number) {
    if (number == null) return null;
    for (final s in all) {
      if (s.number == number) return s;
    }
    return null;
  }

  static const _distantDo = LocalizedText(
    en: 'Fishing boats and trawlers in the deep sea: come back towards the coast. Everyone else: follow the weather news.',
    bn: 'গভীর সমুদ্রে থাকা মাছ ধরার নৌকা ও ট্রলার উপকূলের কাছে ফিরে আসুন। অন্যরা আবহাওয়ার খবর শুনতে থাকুন।',
  );
  static const _localDo = LocalizedText(
    en: 'Boats and trawlers stay in a safe place on shore. Coastal families: pack the emergency bag, store drinking water and dry food, put documents in a plastic bag, and find your nearest cyclone shelter.',
    bn: 'নৌকা ও ট্রলার নিরাপদ জায়গায় থাকুন। উপকূলের পরিবার: জরুরি ব্যাগ গুছিয়ে নিন, খাবার পানি ও শুকনো খাবার রাখুন, কাগজপত্র পলিথিনে ভরে রাখুন এবং কাছের আশ্রয়কেন্দ্র কোথায় জেনে নিন।',
  );
  static const _dangerDo = LocalizedText(
    en: 'Coast and islands: take children, older people, people with disabilities and pregnant women to a cyclone shelter now. Everyone else be ready to leave, and follow CPP volunteers and local officials.',
    bn: 'উপকূল ও দ্বীপ: শিশু, বয়স্ক, প্রতিবন্ধী ও গর্ভবতী নারীদের এখনই আশ্রয়কেন্দ্রে নিয়ে যান। বাকিরা বের হওয়ার জন্য প্রস্তুত থাকুন এবং সিপিপি স্বেচ্ছাসেবক ও স্থানীয় প্রশাসনের নির্দেশ মানুন।',
  );
  static const _greatDangerDo = LocalizedText(
    en: 'Go to a cyclone shelter or a strong concrete building now. Do not wait for the wind. Do not go back until officials say it is safe.',
    bn: 'এখনই আশ্রয়কেন্দ্র বা মজবুত পাকা ভবনে চলে যান। বাতাস শুরু হওয়ার অপেক্ষা করবেন না। প্রশাসন নিরাপদ না বলা পর্যন্ত ফিরে যাবেন না।',
  );

  static const all = <StormSignal>[
    StormSignal(
      1,
      LocalizedText(en: 'Distant cautionary signal', bn: 'দূরবর্তী সতর্ক সংকেত'),
      LocalizedText(
        en: 'Squally weather far out at sea, where a storm may form. Ships leaving port may meet bad weather.',
        bn: 'গভীর সমুদ্রে ঝোড়ো হাওয়া রয়েছে, সেখানে ঝড় সৃষ্টি হতে পারে। বন্দর ছেড়ে যাওয়া জাহাজ দুর্যোগে পড়তে পারে।',
      ),
      _distantDo,
    ),
    StormSignal(
      2,
      LocalizedText(en: 'Distant warning signal', bn: 'দূরবর্তী হুঁশিয়ারি সংকেত'),
      LocalizedText(
        en: 'A storm (62–88 km/h) has formed far out at sea. Ships leaving port may be in danger.',
        bn: 'গভীর সমুদ্রে ঘূর্ণিঝড় (ঘণ্টায় ৬২–৮৮ কিমি) সৃষ্টি হয়েছে। বন্দর ছেড়ে যাওয়া জাহাজ বিপদে পড়তে পারে।',
      ),
      _distantDo,
    ),
    StormSignal(
      3,
      LocalizedText(en: 'Local cautionary signal', bn: 'স্থানীয় সতর্ক সংকেত'),
      LocalizedText(
        en: 'The port is threatened by squally weather (gusts of 40–50 km/h).',
        bn: 'বন্দর ঝোড়ো আবহাওয়ার কবলে পড়তে পারে (দমকা হাওয়া ঘণ্টায় ৪০–৫০ কিমি)।',
      ),
      _localDo,
    ),
    StormSignal(
      4,
      LocalizedText(en: 'Local warning signal', bn: 'স্থানীয় হুঁশিয়ারি সংকেত'),
      LocalizedText(
        en: 'The port is threatened by a storm (51–61 km/h), but the danger is not yet great enough for extreme measures.',
        bn: 'বন্দর ঝড়ের (ঘণ্টায় ৫১–৬১ কিমি) কবলে পড়তে পারে, তবে চরম ব্যবস্থা নেওয়ার মতো বিপদ এখনো আসেনি।',
      ),
      _localDo,
    ),
    StormSignal(
      5,
      LocalizedText(en: 'Danger signal', bn: 'বিপদ সংকেত'),
      LocalizedText(
        en: 'A light or moderate cyclone (62–88 km/h) is expected to cross the coast south of Chattogram or Cox\'s Bazar port, or east of Mongla port.',
        bn: 'হালকা বা মাঝারি ঘূর্ণিঝড় (ঘণ্টায় ৬২–৮৮ কিমি) চট্টগ্রাম বা কক্সবাজার বন্দরের দক্ষিণ দিয়ে, অথবা মোংলা বন্দরের পূর্ব দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _dangerDo,
    ),
    StormSignal(
      6,
      LocalizedText(en: 'Danger signal', bn: 'বিপদ সংকেত'),
      LocalizedText(
        en: 'A light or moderate cyclone (62–88 km/h) is expected to cross the coast north of Chattogram or Cox\'s Bazar port, or west of Mongla port.',
        bn: 'হালকা বা মাঝারি ঘূর্ণিঝড় (ঘণ্টায় ৬২–৮৮ কিমি) চট্টগ্রাম বা কক্সবাজার বন্দরের উত্তর দিয়ে, অথবা মোংলা বন্দরের পশ্চিম দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _dangerDo,
    ),
    StormSignal(
      7,
      LocalizedText(en: 'Danger signal', bn: 'বিপদ সংকেত'),
      LocalizedText(
        en: 'A light or moderate cyclone (62–88 km/h) is expected to cross the coast over or near the port.',
        bn: 'হালকা বা মাঝারি ঘূর্ণিঝড় (ঘণ্টায় ৬২–৮৮ কিমি) বন্দরের ওপর দিয়ে বা কাছ দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _dangerDo,
    ),
    StormSignal(
      8,
      LocalizedText(en: 'Great danger signal', bn: 'মহাবিপদ সংকেত'),
      LocalizedText(
        en: 'A severe cyclone (89 km/h or more) is expected to cross the coast south of Chattogram or Cox\'s Bazar port, or east of Mongla port.',
        bn: 'প্রবল ঘূর্ণিঝড় (ঘণ্টায় ৮৯ কিমি বা বেশি) চট্টগ্রাম বা কক্সবাজার বন্দরের দক্ষিণ দিয়ে, অথবা মোংলা বন্দরের পূর্ব দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _greatDangerDo,
    ),
    StormSignal(
      9,
      LocalizedText(en: 'Great danger signal', bn: 'মহাবিপদ সংকেত'),
      LocalizedText(
        en: 'A severe cyclone (89 km/h or more) is expected to cross the coast north of Chattogram or Cox\'s Bazar port, or west of Mongla port.',
        bn: 'প্রবল ঘূর্ণিঝড় (ঘণ্টায় ৮৯ কিমি বা বেশি) চট্টগ্রাম বা কক্সবাজার বন্দরের উত্তর দিয়ে, অথবা মোংলা বন্দরের পশ্চিম দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _greatDangerDo,
    ),
    StormSignal(
      10,
      LocalizedText(en: 'Great danger signal', bn: 'মহাবিপদ সংকেত'),
      LocalizedText(
        en: 'A severe cyclone (89 km/h or more) is expected to cross the coast over or near the port.',
        bn: 'প্রবল ঘূর্ণিঝড় (ঘণ্টায় ৮৯ কিমি বা বেশি) বন্দরের ওপর দিয়ে বা কাছ দিয়ে উপকূল অতিক্রম করতে পারে।',
      ),
      _greatDangerDo,
    ),
    StormSignal(
      11,
      LocalizedText(en: 'Communication failure signal', bn: 'যোগাযোগ বিচ্ছিন্ন সংকেত'),
      LocalizedText(
        en: 'Contact with the Storm Warning Centre is lost, and local officials believe a devastating cyclone is coming.',
        bn: 'আবহাওয়া বিপদ সংকেত কেন্দ্রের সঙ্গে যোগাযোগ বিচ্ছিন্ন হয়ে গেছে, এবং স্থানীয় কর্মকর্তারা মনে করছেন ভয়াবহ ঘূর্ণিঝড় আসছে।',
      ),
      _greatDangerDo,
    ),
  ];
}
