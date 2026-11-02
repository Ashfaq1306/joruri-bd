/// Bangladesh: 8 divisions and 64 districts, in English and Bangla.
/// Generated once from a reviewed list; edit here, not by hand elsewhere.
class BdDivision {
  const BdDivision(this.id, this.en, this.bn);
  final String id;
  final String en;
  final String bn;
  String name(String languageCode) => languageCode == 'bn' ? bn : en;
}

class BdDistrict {
  const BdDistrict(this.id, this.divisionId, this.en, this.bn);
  final String id;
  final String divisionId;
  final String en;
  final String bn;
  String name(String languageCode) => languageCode == 'bn' ? bn : en;
}

abstract final class BdLocations {
  static const divisions = <BdDivision>[
    BdDivision('barishal', 'Barishal', 'বরিশাল'),
    BdDivision('chattogram', 'Chattogram', 'চট্টগ্রাম'),
    BdDivision('dhaka', 'Dhaka', 'ঢাকা'),
    BdDivision('khulna', 'Khulna', 'খুলনা'),
    BdDivision('mymensingh', 'Mymensingh', 'ময়মনসিংহ'),
    BdDivision('rajshahi', 'Rajshahi', 'রাজশাহী'),
    BdDivision('rangpur', 'Rangpur', 'রংপুর'),
    BdDivision('sylhet', 'Sylhet', 'সিলেট'),
  ];

  static const districts = <BdDistrict>[
    BdDistrict('barguna', 'barishal', 'Barguna', 'বরগুনা'),
    BdDistrict('barishal', 'barishal', 'Barishal', 'বরিশাল'),
    BdDistrict('bhola', 'barishal', 'Bhola', 'ভোলা'),
    BdDistrict('jhalokati', 'barishal', 'Jhalokati', 'ঝালকাঠি'),
    BdDistrict('patuakhali', 'barishal', 'Patuakhali', 'পটুয়াখালী'),
    BdDistrict('pirojpur', 'barishal', 'Pirojpur', 'পিরোজপুর'),
    BdDistrict('bandarban', 'chattogram', 'Bandarban', 'বান্দরবান'),
    BdDistrict('brahmanbaria', 'chattogram', 'Brahmanbaria', 'ব্রাহ্মণবাড়িয়া'),
    BdDistrict('chandpur', 'chattogram', 'Chandpur', 'চাঁদপুর'),
    BdDistrict('chattogram', 'chattogram', 'Chattogram', 'চট্টগ্রাম'),
    BdDistrict('cumilla', 'chattogram', 'Cumilla', 'কুমিল্লা'),
    BdDistrict('coxs-bazar', 'chattogram', 'Cox\'s Bazar', 'কক্সবাজার'),
    BdDistrict('feni', 'chattogram', 'Feni', 'ফেনী'),
    BdDistrict('khagrachhari', 'chattogram', 'Khagrachhari', 'খাগড়াছড়ি'),
    BdDistrict('lakshmipur', 'chattogram', 'Lakshmipur', 'লক্ষ্মীপুর'),
    BdDistrict('noakhali', 'chattogram', 'Noakhali', 'নোয়াখালী'),
    BdDistrict('rangamati', 'chattogram', 'Rangamati', 'রাঙ্গামাটি'),
    BdDistrict('dhaka', 'dhaka', 'Dhaka', 'ঢাকা'),
    BdDistrict('faridpur', 'dhaka', 'Faridpur', 'ফরিদপুর'),
    BdDistrict('gazipur', 'dhaka', 'Gazipur', 'গাজীপুর'),
    BdDistrict('gopalganj', 'dhaka', 'Gopalganj', 'গোপালগঞ্জ'),
    BdDistrict('kishoreganj', 'dhaka', 'Kishoreganj', 'কিশোরগঞ্জ'),
    BdDistrict('madaripur', 'dhaka', 'Madaripur', 'মাদারীপুর'),
    BdDistrict('manikganj', 'dhaka', 'Manikganj', 'মানিকগঞ্জ'),
    BdDistrict('munshiganj', 'dhaka', 'Munshiganj', 'মুন্সিগঞ্জ'),
    BdDistrict('narayanganj', 'dhaka', 'Narayanganj', 'নারায়ণগঞ্জ'),
    BdDistrict('narsingdi', 'dhaka', 'Narsingdi', 'নরসিংদী'),
    BdDistrict('rajbari', 'dhaka', 'Rajbari', 'রাজবাড়ী'),
    BdDistrict('shariatpur', 'dhaka', 'Shariatpur', 'শরীয়তপুর'),
    BdDistrict('tangail', 'dhaka', 'Tangail', 'টাঙ্গাইল'),
    BdDistrict('bagerhat', 'khulna', 'Bagerhat', 'বাগেরহাট'),
    BdDistrict('chuadanga', 'khulna', 'Chuadanga', 'চুয়াডাঙ্গা'),
    BdDistrict('jashore', 'khulna', 'Jashore', 'যশোর'),
    BdDistrict('jhenaidah', 'khulna', 'Jhenaidah', 'ঝিনাইদহ'),
    BdDistrict('khulna', 'khulna', 'Khulna', 'খুলনা'),
    BdDistrict('kushtia', 'khulna', 'Kushtia', 'কুষ্টিয়া'),
    BdDistrict('magura', 'khulna', 'Magura', 'মাগুরা'),
    BdDistrict('meherpur', 'khulna', 'Meherpur', 'মেহেরপুর'),
    BdDistrict('narail', 'khulna', 'Narail', 'নড়াইল'),
    BdDistrict('satkhira', 'khulna', 'Satkhira', 'সাতক্ষীরা'),
    BdDistrict('jamalpur', 'mymensingh', 'Jamalpur', 'জামালপুর'),
    BdDistrict('mymensingh', 'mymensingh', 'Mymensingh', 'ময়মনসিংহ'),
    BdDistrict('netrokona', 'mymensingh', 'Netrokona', 'নেত্রকোনা'),
    BdDistrict('sherpur', 'mymensingh', 'Sherpur', 'শেরপুর'),
    BdDistrict('bogura', 'rajshahi', 'Bogura', 'বগুড়া'),
    BdDistrict('chapainawabganj', 'rajshahi', 'Chapainawabganj', 'চাঁপাইনবাবগঞ্জ'),
    BdDistrict('joypurhat', 'rajshahi', 'Joypurhat', 'জয়পুরহাট'),
    BdDistrict('naogaon', 'rajshahi', 'Naogaon', 'নওগাঁ'),
    BdDistrict('natore', 'rajshahi', 'Natore', 'নাটোর'),
    BdDistrict('pabna', 'rajshahi', 'Pabna', 'পাবনা'),
    BdDistrict('rajshahi', 'rajshahi', 'Rajshahi', 'রাজশাহী'),
    BdDistrict('sirajganj', 'rajshahi', 'Sirajganj', 'সিরাজগঞ্জ'),
    BdDistrict('dinajpur', 'rangpur', 'Dinajpur', 'দিনাজপুর'),
    BdDistrict('gaibandha', 'rangpur', 'Gaibandha', 'গাইবান্ধা'),
    BdDistrict('kurigram', 'rangpur', 'Kurigram', 'কুড়িগ্রাম'),
    BdDistrict('lalmonirhat', 'rangpur', 'Lalmonirhat', 'লালমনিরহাট'),
    BdDistrict('nilphamari', 'rangpur', 'Nilphamari', 'নীলফামারী'),
    BdDistrict('panchagarh', 'rangpur', 'Panchagarh', 'পঞ্চগড়'),
    BdDistrict('rangpur', 'rangpur', 'Rangpur', 'রংপুর'),
    BdDistrict('thakurgaon', 'rangpur', 'Thakurgaon', 'ঠাকুরগাঁও'),
    BdDistrict('habiganj', 'sylhet', 'Habiganj', 'হবিগঞ্জ'),
    BdDistrict('moulvibazar', 'sylhet', 'Moulvibazar', 'মৌলভীবাজার'),
    BdDistrict('sunamganj', 'sylhet', 'Sunamganj', 'সুনামগঞ্জ'),
    BdDistrict('sylhet', 'sylhet', 'Sylhet', 'সিলেট'),
  ];

  /// Older spellings still common in spreadsheets.
  static const _aliases = <String, String>{
    'chittagong': 'chattogram',
    'comilla': 'cumilla',
    'barisal': 'barishal',
    'jessore': 'jashore',
    'bogra': 'bogura',
    'chapai nawabganj': 'chapainawabganj',
    'nawabganj': 'chapainawabganj',
    'coxsbazar': 'coxs-bazar',
    'cox bazar': 'coxs-bazar',
    'jhalakathi': 'jhalokati',
    'jhalakati': 'jhalokati',
    'maulvibazar': 'moulvibazar',
    'netrakona': 'netrokona',
    'lakshmipur': 'lakshmipur',
    'laxmipur': 'lakshmipur',
    'khagrachari': 'khagrachhari',
    'rangamati': 'rangamati',
    'jhenaidaha': 'jhenaidah',
    'narshingdi': 'narsingdi',
  };

  static BdDivision? division(String? id) {
    for (final d in divisions) {
      if (d.id == id) return d;
    }
    return null;
  }

  static BdDistrict? district(String? id) {
    for (final d in districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  static List<BdDistrict> districtsOf(String divisionId) =>
      districts.where((d) => d.divisionId == divisionId).toList(growable: false);

  /// Finds a district by id, English or Bangla name, or an old spelling.
  static BdDistrict? findDistrict(String input) {
    final key = input.trim().toLowerCase().replaceAll("'", '');
    if (key.isEmpty) return null;
    final id = _aliases[key] ?? key.replaceAll(RegExp(r'[^a-z\u0980-\u09FF]+'), '-');
    for (final d in districts) {
      if (d.id == id || d.bn == input.trim() || d.en.toLowerCase().replaceAll("'", '') == key) return d;
    }
    return null;
  }
}
