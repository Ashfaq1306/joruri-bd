import '../blood/blood_group.dart';

/// A blood donor whose number may be shown to people who need blood.
///
/// Only donors who agreed to share their number are stored at all
/// ([shareConsent]); the import tool rejects rows without consent.
class Donor {
  const Donor({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.phone,
    required this.districtId,
    this.area = '',
    this.available = true,
    this.lastDonation,
    this.verified = false,
    this.shareConsent = true,
    this.demo = false,
  });

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
        id: json['id'] as String,
        name: json['name'] as String,
        bloodGroup: BloodGroup.parse(json['bloodGroup'] as String?) ?? BloodGroup.oPos,
        phone: json['phone'] as String,
        districtId: json['districtId'] as String,
        area: (json['area'] as String?) ?? '',
        available: (json['available'] as bool?) ?? true,
        lastDonation: DateTime.tryParse((json['lastDonation'] as String?) ?? ''),
        verified: (json['verified'] as bool?) ?? false,
        shareConsent: (json['shareConsent'] as bool?) ?? false,
        demo: (json['demo'] as bool?) ?? false,
      );

  final String id;
  final String name;
  final BloodGroup bloodGroup;

  /// Normalized: +8801XXXXXXXXX for Bangladeshi mobiles.
  final String phone;
  final String districtId;

  /// Neighbourhood or upazila, as the donor wrote it.
  final String area;
  final bool available;
  final DateTime? lastDonation;

  /// Checked by an admin (called, or confirmed by a blood bank).
  final bool verified;
  final bool shareConsent;

  /// Sample data for testing; never shipped in a release build.
  final bool demo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bloodGroup': bloodGroup.label,
        'phone': phone,
        'districtId': districtId,
        'area': area,
        'available': available,
        if (lastDonation != null) 'lastDonation': lastDonation!.toIso8601String().substring(0, 10),
        'verified': verified,
        'shareConsent': shareConsent,
        if (demo) 'demo': true,
      };
}
