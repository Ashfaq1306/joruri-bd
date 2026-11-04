import '../geo/bd_locations.dart';

/// Which service a local station belongs to.
enum StationService {
  police,
  fire;

  static StationService parse(Object? v) => v == 'fire' ? StationService.fire : StationService.police;
}

/// A local police station (thana) or fire station: who to call nearby.
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.districtId,
    required this.phone,
    this.service = StationService.police,
    this.nameBn = '',
    this.unit = '',
    this.unitBn = '',
    this.area = '',
    this.address = '',
    this.otherPhones = const [],
    this.email = '',
    this.latitude,
    this.longitude,
    this.open24h = true,
    this.source = '',
    this.sourceUrl = '',
    this.checkedOn = '',
    this.verified = false,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        id: json['id'] as String,
        name: json['name'] as String,
        districtId: json['districtId'] as String,
        phone: (json['phone'] as String?) ?? '',
        service: StationService.parse(json['service']),
        nameBn: (json['nameBn'] as String?) ?? '',
        unit: (json['unit'] as String?) ?? '',
        unitBn: (json['unitBn'] as String?) ?? '',
        area: (json['area'] as String?) ?? '',
        address: (json['address'] as String?) ?? '',
        otherPhones: ((json['otherPhones'] as List?) ?? const []).whereType<String>().toList(growable: false),
        email: (json['email'] as String?) ?? '',
        latitude: (json['lat'] as num?)?.toDouble(),
        longitude: (json['lng'] as num?)?.toDouble(),
        open24h: (json['open24h'] as bool?) ?? true,
        source: (json['source'] as String?) ?? '',
        sourceUrl: (json['sourceUrl'] as String?) ?? '',
        checkedOn: (json['checkedOn'] as String?) ?? '',
        verified: (json['verified'] as bool?) ?? false,
      );

  final String id;
  final String name;
  final String districtId;

  /// The officer in charge (police) or the station (fire); may be empty.
  final String phone;
  final StationService service;
  final String nameBn;

  /// Metropolitan unit, e.g. "Dhaka Metropolitan Police (DMP)"; empty for district police.
  final String unit;
  final String unitBn;
  final String area;
  final String address;
  final List<String> otherPhones;
  final String email;
  final double? latitude;
  final double? longitude;
  final bool open24h;
  final String source;
  final String sourceUrl;

  /// ISO date the number was last compared with its source.
  final String checkedOn;
  final bool verified;

  String displayName(String languageCode) => languageCode == 'bn' && nameBn.isNotEmpty ? nameBn : name;
  String displayUnit(String languageCode) => languageCode == 'bn' && unitBn.isNotEmpty ? unitBn : unit;

  List<String> get allPhones => [if (phone.isNotEmpty) phone, ...otherPhones.where((p) => p != phone)];

  /// Lower-case text searched by the name box (both languages, area, address).
  String get searchText {
    final d = BdLocations.district(districtId);
    return '$name $nameBn $area $address $unit ${d?.en ?? ''} ${d?.bn ?? ''}'.toLowerCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'districtId': districtId,
        'phone': phone,
        if (service != StationService.police) 'service': service.name,
        if (nameBn.isNotEmpty) 'nameBn': nameBn,
        if (unit.isNotEmpty) 'unit': unit,
        if (unitBn.isNotEmpty) 'unitBn': unitBn,
        if (area.isNotEmpty) 'area': area,
        if (address.isNotEmpty) 'address': address,
        if (otherPhones.isNotEmpty) 'otherPhones': otherPhones,
        if (email.isNotEmpty) 'email': email,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        'open24h': open24h,
        if (source.isNotEmpty) 'source': source,
        if (sourceUrl.isNotEmpty) 'sourceUrl': sourceUrl,
        if (checkedOn.isNotEmpty) 'checkedOn': checkedOn,
        if (verified) 'verified': true,
      };
}

/// Stations matching a search, Metropolitan/Sadar first then by name.
List<Station> searchStations(List<Station> all, {String? districtId, String text = ''}) {
  final q = text.trim().toLowerCase();
  final out = [
    for (final s in all)
      if ((districtId == null || s.districtId == districtId) && (q.isEmpty || s.searchText.contains(q))) s,
  ];
  int rank(Station s) => s.unit.isNotEmpty ? 0 : (RegExp(r'sadar|kotwali', caseSensitive: false).hasMatch(s.name) ? 1 : 2);
  out.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return out;
}
