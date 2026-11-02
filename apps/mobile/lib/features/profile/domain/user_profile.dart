import 'package:joruri_core/joruri_core.dart';

/// The person using the app. Name, mobile, blood group and district are
/// required. Saved on this phone; Phase 4 verifies the number by OTP and
/// syncs it to the online donor list.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.districtId,
    this.divisionId,
    this.area = '',
    this.donor = true,
    this.available = true,
    this.consent = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String,
        phone: json['phone'] as String,
        bloodGroup: BloodGroup.parse(json['bloodGroup'] as String?) ?? BloodGroup.oPos,
        districtId: json['districtId'] as String,
        divisionId: json['divisionId'] as String?,
        area: (json['area'] as String?) ?? '',
        donor: (json['donor'] as bool?) ?? true,
        available: (json['available'] as bool?) ?? true,
        consent: (json['consent'] as bool?) ?? false,
      );

  final String name;

  /// Normalized: +8801XXXXXXXXX.
  final String phone;
  final BloodGroup bloodGroup;
  final String districtId;
  final String? divisionId;
  final String area;

  /// Wants to donate blood.
  final bool donor;

  /// Can donate right now; the person switches this themselves.
  final bool available;

  /// Agreed to show name, area and number to people who need blood.
  final bool consent;

  bool get listedAsDonor => donor && consent;

  /// This person as an entry in the donor search (id "me").
  Donor? toDonor() => listedAsDonor
      ? Donor(
          id: 'me',
          name: name,
          bloodGroup: bloodGroup,
          phone: phone,
          districtId: districtId,
          area: area,
          available: available,
          shareConsent: true,
        )
      : null;

  UserProfile copyWith({bool? available}) => UserProfile(
        name: name,
        phone: phone,
        bloodGroup: bloodGroup,
        districtId: districtId,
        divisionId: divisionId,
        area: area,
        donor: donor,
        available: available ?? this.available,
        consent: consent,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'bloodGroup': bloodGroup.label,
        'districtId': districtId,
        if (divisionId != null) 'divisionId': divisionId,
        'area': area,
        'donor': donor,
        'available': available,
        'consent': consent,
      };
}
