import '../geo/bd_locations.dart';

/// One test a hospital offers, with its price in taka.
class TestPrice {
  const TestPrice({required this.name, this.aliases = const [], this.priceBdt, this.note = ''});

  factory TestPrice.fromJson(Map<String, dynamic> json) => TestPrice(
        name: json['name'] as String,
        aliases: ((json['aliases'] as List?) ?? const []).whereType<String>().toList(growable: false),
        priceBdt: (json['priceBdt'] as num?)?.round(),
        note: (json['note'] as String?) ?? '',
      );

  final String name;

  /// Other names people search for: "Complete Blood Count", "সিবিসি", "রক্ত পরীক্ষা".
  final List<String> aliases;

  /// null = the hospital did not give a price; the app says "call for price".
  final int? priceBdt;
  final String note;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (name.toLowerCase().contains(q)) return true;
    return aliases.any((a) => a.toLowerCase().contains(q));
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (priceBdt != null) 'priceBdt': priceBdt,
        if (note.isNotEmpty) 'note': note,
      };
}

class Hospital {
  const Hospital({
    required this.id,
    required this.name,
    required this.districtId,
    required this.phone,
    this.area = '',
    this.address = '',
    this.emergencyPhone,
    this.emergency = false,
    this.bloodBank = false,
    this.ambulance = false,
    this.icu = false,
    this.open24h = false,
    this.pricesCheckedOn,
    this.tests = const [],
    this.verified = false,
    this.demo = false,
    this.nameBn = '',
    this.kind = '',
    this.kindBn = '',
    this.government = false,
    this.otherPhones = const [],
    this.email = '',
    this.website = '',
    this.latitude,
    this.longitude,
    this.beds,
    this.source = '',
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        id: json['id'] as String,
        name: json['name'] as String,
        districtId: json['districtId'] as String,
        phone: (json['phone'] as String?) ?? '',
        area: (json['area'] as String?) ?? '',
        address: (json['address'] as String?) ?? '',
        emergencyPhone: json['emergencyPhone'] as String?,
        emergency: (json['emergency'] as bool?) ?? false,
        bloodBank: (json['bloodBank'] as bool?) ?? false,
        ambulance: (json['ambulance'] as bool?) ?? false,
        icu: (json['icu'] as bool?) ?? false,
        open24h: (json['open24h'] as bool?) ?? false,
        pricesCheckedOn: json['pricesCheckedOn'] as String?,
        tests: ((json['tests'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TestPrice.fromJson)
            .toList(growable: false),
        verified: (json['verified'] as bool?) ?? false,
        demo: (json['demo'] as bool?) ?? false,
        nameBn: (json['nameBn'] as String?) ?? '',
        kind: (json['kind'] as String?) ?? '',
        kindBn: (json['kindBn'] as String?) ?? '',
        government: (json['government'] as bool?) ?? false,
        otherPhones: ((json['otherPhones'] as List?) ?? const []).whereType<String>().toList(growable: false),
        email: (json['email'] as String?) ?? '',
        website: (json['website'] as String?) ?? '',
        latitude: (json['lat'] as num?)?.toDouble(),
        longitude: (json['lng'] as num?)?.toDouble(),
        beds: (json['beds'] as num?)?.toInt(),
        source: (json['source'] as String?) ?? '',
      );

  final String id;
  final String name;
  final String districtId;

  /// Main number; empty when the source gave none (the app then offers
  /// [otherPhones] or a map search instead of a call button).
  final String phone;
  final String area;
  final String address;
  final String? emergencyPhone;
  final bool emergency;
  final bool bloodBank;
  final bool ambulance;
  final bool icu;
  final bool open24h;

  /// ISO date the prices were last confirmed with the hospital.
  final String? pricesCheckedOn;
  final List<TestPrice> tests;
  final bool verified;
  final bool demo;

  /// Bangla name (shown when the app is in Bangla).
  final String nameBn;

  /// Facility type, e.g. "Upazila Health Complex", "Private Hospital / Clinic".
  final String kind;
  final String kindBn;
  final bool government;

  /// Land lines and second mobiles.
  final List<String> otherPhones;
  final String email;
  final String website;
  final double? latitude;
  final double? longitude;
  final int? beds;

  /// Where the details came from, e.g. "DGHS Facility Registry".
  final String source;

  String displayName(String languageCode) => languageCode == 'bn' && nameBn.isNotEmpty ? nameBn : name;
  String displayKind(String languageCode) => languageCode == 'bn' && kindBn.isNotEmpty ? kindBn : kind;

  /// Every number to call, main one first.
  List<String> get allPhones => [if (phone.isNotEmpty) phone, ...otherPhones.where((p) => p != phone)];

  /// Lower-case text searched by the name box (both languages, area, address).
  String get searchText => '$name $nameBn $area $address $kind'.toLowerCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'districtId': districtId,
        'phone': phone,
        if (area.isNotEmpty) 'area': area,
        if (address.isNotEmpty) 'address': address,
        if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        'emergency': emergency,
        'bloodBank': bloodBank,
        'ambulance': ambulance,
        'icu': icu,
        'open24h': open24h,
        if (pricesCheckedOn != null) 'pricesCheckedOn': pricesCheckedOn,
        'tests': tests.map((t) => t.toJson()).toList(),
        'verified': verified,
        if (demo) 'demo': true,
        if (nameBn.isNotEmpty) 'nameBn': nameBn,
        if (kind.isNotEmpty) 'kind': kind,
        if (kindBn.isNotEmpty) 'kindBn': kindBn,
        if (government) 'government': true,
        if (otherPhones.isNotEmpty) 'otherPhones': otherPhones,
        if (email.isNotEmpty) 'email': email,
        if (website.isNotEmpty) 'website': website,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (beds != null) 'beds': beds,
        if (source.isNotEmpty) 'source': source,
      };
}

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.districtId,
    required this.phone,
    this.area = '',
    this.address = '',
    this.open24h = false,
    this.verified = false,
    this.demo = false,
    this.licence = '',
    this.licenceValidUpto,
    this.source = '',
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
        id: json['id'] as String,
        name: json['name'] as String,
        districtId: json['districtId'] as String,
        phone: (json['phone'] as String?) ?? '',
        area: (json['area'] as String?) ?? '',
        address: (json['address'] as String?) ?? '',
        open24h: (json['open24h'] as bool?) ?? false,
        verified: (json['verified'] as bool?) ?? false,
        demo: (json['demo'] as bool?) ?? false,
        licence: (json['licence'] as String?) ?? '',
        licenceValidUpto: DateTime.tryParse((json['validUpto'] as String?) ?? ''),
        source: (json['source'] as String?) ?? '',
      );

  final String id;
  final String name;
  final String districtId;

  /// Empty when the register has no number; the app offers directions instead.
  final String phone;

  /// Upazila / thana.
  final String area;
  final String address;
  final bool open24h;
  final bool verified;
  final bool demo;

  /// Drug licence number from the DGDA register (empty for admin-added shops).
  final String licence;

  /// Last day of the licence in the DGDA register. null = not known.
  final DateTime? licenceValidUpto;

  /// Where the entry comes from, e.g. "DGDA".
  final String source;

  bool get hasPhone => phone.trim().isNotEmpty;

  /// true / false from the register's date; null when there is no date.
  bool? licenceValidOn(DateTime day) {
    final until = licenceValidUpto;
    if (until == null) return null;
    return !until.isBefore(DateTime(day.year, day.month, day.day));
  }

  String get searchText => '$name $area $address'.toLowerCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'districtId': districtId,
        'phone': phone,
        if (area.isNotEmpty) 'area': area,
        if (address.isNotEmpty) 'address': address,
        'open24h': open24h,
        'verified': verified,
        if (demo) 'demo': true,
        if (licence.isNotEmpty) 'licence': licence,
        if (licenceValidUpto != null) 'validUpto': licenceValidUpto!.toIso8601String().substring(0, 10),
        if (source.isNotEmpty) 'source': source,
      };
}

/// Where to look: all Bangladesh, a division, a district, and an area text.
class PlaceFilter {
  const PlaceFilter({this.divisionId, this.districtId, this.areaText = ''});

  final String? divisionId;
  final String? districtId;
  final String areaText;

  bool accepts(String districtId, String area) {
    if (!acceptsDistrict(districtId)) return false;
    final text = areaText.trim().toLowerCase();
    return text.isEmpty || area.toLowerCase().contains(text);
  }

  /// Division and district only (the caller matches the text itself, e.g.
  /// against name and address).
  bool acceptsDistrict(String districtId) {
    if (this.districtId != null && districtId != this.districtId) return false;
    if (this.districtId == null && divisionId != null && BdLocations.district(districtId)?.divisionId != divisionId) {
      return false;
    }
    return true;
  }

  PlaceFilter copyWith({String? Function()? divisionId, String? Function()? districtId, String? areaText}) =>
      PlaceFilter(
        divisionId: divisionId != null ? divisionId() : this.divisionId,
        districtId: districtId != null ? districtId() : this.districtId,
        areaText: areaText ?? this.areaText,
      );
}

/// A test at a specific hospital: one row in "where can I do this test?".
class TestOffer {
  const TestOffer(this.hospital, this.test);

  final Hospital hospital;
  final TestPrice test;
}

/// Every hospital in the area that lists a matching test, cheapest first.
/// Tests without a price come last. The filter's text matches the hospital's
/// name, area or address (the same box is the name search on the Hospitals
/// tab; matching the area alone made "CBC" + "Dhaka Medical" find nothing).
List<TestOffer> findTest(List<Hospital> hospitals, String query, PlaceFilter where) {
  final text = where.areaText.trim().toLowerCase();
  final offers = <TestOffer>[
    for (final h in hospitals)
      if (where.acceptsDistrict(h.districtId) && (text.isEmpty || h.searchText.contains(text)))
        for (final t in h.tests)
          if (t.matches(query)) TestOffer(h, t),
  ];
  offers.sort((a, b) {
    final pa = a.test.priceBdt, pb = b.test.priceBdt;
    if (pa == null && pb == null) return a.hospital.name.compareTo(b.hospital.name);
    if (pa == null) return 1;
    if (pb == null) return -1;
    return pa.compareTo(pb);
  });
  return offers;
}
