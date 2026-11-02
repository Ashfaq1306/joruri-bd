import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/features/blood/data/donor_repository.dart';
import 'package:joruri_bd/features/blood/data/remote_donors.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';

final bloodQueryProvider = NotifierProvider<BloodQueryController, DonorQuery>(BloodQueryController.new);

/// The current search. Division and district are remembered on this phone,
/// so next time the list already shows your area.
class BloodQueryController extends Notifier<DonorQuery> {
  static const _divisionKey = 'blood.divisionId';
  static const _districtKey = 'blood.districtId';

  @override
  DonorQuery build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return DonorQuery(
      needed: BloodGroup.aPos,
      divisionId: prefs.getString(_divisionKey),
      districtId: prefs.getString(_districtKey),
    );
  }

  void setGroup(BloodGroup group) => state = state.copyWith(needed: group);

  void setDivision(String? id) {
    state = state.copyWith(divisionId: () => id, districtId: () => null);
    _remember();
  }

  void setDistrict(String? id) {
    final division = id == null ? state.divisionId : BdLocations.district(id)?.divisionId;
    state = state.copyWith(districtId: () => id, divisionId: () => division);
    _remember();
  }

  void setArea(String text) => state = state.copyWith(areaText: text);

  void setIncludeCompatible(bool value) => state = state.copyWith(includeCompatible: value);

  void setAvailableOnly(bool value) => state = state.copyWith(availableOnly: value);

  void _remember() {
    final prefs = ref.read(sharedPreferencesProvider);
    final division = state.divisionId;
    final district = state.districtId;
    division == null ? prefs.remove(_divisionKey) : prefs.setString(_divisionKey, division);
    district == null ? prefs.remove(_districtKey) : prefs.setString(_districtKey, district);
  }
}

/// Donors matching the current search, best matches first. Includes the
/// person using the app when they chose to be listed (shown as "You").
final donorResultsProvider = Provider<AsyncValue<List<Donor>>>((ref) {
  final query = ref.watch(bloodQueryProvider);
  // Live online list when the person is verified and online; otherwise the
  // bundled list on the phone.
  final groups = (query.includeCompatible ? query.needed.canReceiveFrom : [query.needed]).map((g) => g.label).join(',');
  final live = ref.watch(remoteDonorsProvider(groups)).valueOrNull;
  if (live != null) return AsyncData(searchDonors(live, query));
  final me = ref.watch(myDonorProvider);
  return ref.watch(allDonorsProvider).whenData((all) => searchDonors(me == null ? all : [...all, me], query));
});
