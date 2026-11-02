import '../geo/bd_locations.dart';
import '../models/donor.dart';
import 'blood_group.dart';

/// What the person needing blood is looking for.
class DonorQuery {
  const DonorQuery({
    required this.needed,
    this.includeCompatible = false,
    this.divisionId,
    this.districtId,
    this.areaText = '',
    this.availableOnly = true,
  });

  final BloodGroup needed;

  /// Also list donors of other groups the patient can usually receive.
  final bool includeCompatible;
  final String? divisionId;
  final String? districtId;
  final String areaText;
  final bool availableOnly;

  DonorQuery copyWith({
    BloodGroup? needed,
    bool? includeCompatible,
    String? Function()? divisionId,
    String? Function()? districtId,
    String? areaText,
    bool? availableOnly,
  }) {
    return DonorQuery(
      needed: needed ?? this.needed,
      includeCompatible: includeCompatible ?? this.includeCompatible,
      divisionId: divisionId != null ? divisionId() : this.divisionId,
      districtId: districtId != null ? districtId() : this.districtId,
      areaText: areaText ?? this.areaText,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }
}

/// Filters and orders donors. Pure Dart: the same code will run in the
/// backend when donors live in Firestore.
///
/// Order: exact blood group first, then available, then verified,
/// then whoever donated longest ago (more likely ready), then name.
List<Donor> searchDonors(List<Donor> all, DonorQuery q) {
  final groups = q.includeCompatible ? q.needed.canReceiveFrom : [q.needed];
  final area = q.areaText.trim().toLowerCase();

  final matches = all.where((d) {
    if (!d.shareConsent) return false;
    if (!groups.contains(d.bloodGroup)) return false;
    if (q.availableOnly && !d.available) return false;
    if (q.districtId != null && d.districtId != q.districtId) return false;
    if (q.districtId == null && q.divisionId != null) {
      if (BdLocations.district(d.districtId)?.divisionId != q.divisionId) return false;
    }
    if (area.isNotEmpty && !d.area.toLowerCase().contains(area)) return false;
    return true;
  }).toList();

  int rank(bool v) => v ? 0 : 1;
  final far = DateTime(1900);
  matches.sort((a, b) {
    final byGroup = rank(a.bloodGroup == q.needed).compareTo(rank(b.bloodGroup == q.needed));
    if (byGroup != 0) return byGroup;
    final byAvailable = rank(a.available).compareTo(rank(b.available));
    if (byAvailable != 0) return byAvailable;
    final byVerified = rank(a.verified).compareTo(rank(b.verified));
    if (byVerified != 0) return byVerified;
    final byRest = (a.lastDonation ?? far).compareTo(b.lastDonation ?? far);
    if (byRest != 0) return byRest;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return matches;
}
