import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

Donor _donor(String id, String group, String district, {bool available = true, String area = '', bool consent = true}) =>
    Donor(
      id: id,
      name: 'Donor $id',
      bloodGroup: BloodGroup.parse(group)!,
      phone: '+88017000000$id',
      districtId: district,
      area: area,
      available: available,
      shareConsent: consent,
    );

void main() {
  group('BloodGroup.parse', () {
    test('reads the ways people write blood groups', () {
      expect(BloodGroup.parse('A+'), BloodGroup.aPos);
      expect(BloodGroup.parse('a +'), BloodGroup.aPos);
      expect(BloodGroup.parse('O-ve'), BloodGroup.oNeg);
      expect(BloodGroup.parse('AB positive'), BloodGroup.abPos);
      expect(BloodGroup.parse('B neg'), BloodGroup.bNeg);
      expect(BloodGroup.parse('O\u2212'), BloodGroup.oNeg);
      expect(BloodGroup.parse('C+'), isNull);
    });
  });

  test('compatibility follows the standard table', () {
    expect(BloodGroup.oNeg.canReceiveFrom, [BloodGroup.oNeg]);
    expect(BloodGroup.abPos.canReceiveFrom.length, 8);
    expect(BloodGroup.aPos.canReceiveFrom, containsAll([BloodGroup.aNeg, BloodGroup.oPos, BloodGroup.oNeg]));
    expect(BloodGroup.aPos.canReceiveFrom, isNot(contains(BloodGroup.bPos)));
  });

  test('Bangladesh has 8 divisions and 64 districts, each in a real division', () {
    expect(BdLocations.divisions.length, 8);
    expect(BdLocations.districts.length, 64);
    for (final d in BdLocations.districts) {
      expect(BdLocations.division(d.divisionId), isNotNull, reason: d.id);
    }
    expect(BdLocations.findDistrict('Chittagong')?.id, 'chattogram');
    expect(BdLocations.findDistrict("Cox's Bazar")?.id, 'coxs-bazar');
    expect(BdLocations.findDistrict('ঢাকা')?.id, 'dhaka');
  });

  group('searchDonors', () {
    final donors = [
      _donor('1', 'A+', 'dhaka', area: 'Mirpur'),
      _donor('2', 'O+', 'dhaka'),
      _donor('3', 'A+', 'sylhet'),
      _donor('4', 'A+', 'dhaka', available: false),
      _donor('5', 'A+', 'dhaka', consent: false),
      _donor('6', 'A+', 'gazipur'),
    ];

    test('exact group only by default, available, with consent', () {
      final r = searchDonors(donors, const DonorQuery(needed: BloodGroup.aPos));
      expect(r.map((d) => d.id), ['1', '3', '6']);
    });

    test('district and area filters', () {
      final r = searchDonors(donors, const DonorQuery(needed: BloodGroup.aPos, districtId: 'dhaka', areaText: 'mir'));
      expect(r.map((d) => d.id), ['1']);
    });

    test('division filter covers all its districts', () {
      final r = searchDonors(donors, const DonorQuery(needed: BloodGroup.aPos, divisionId: 'dhaka'));
      expect(r.map((d) => d.id).toSet(), {'1', '6'});
    });

    test('compatible groups come after exact matches', () {
      final r = searchDonors(donors, const DonorQuery(needed: BloodGroup.aPos, districtId: 'dhaka', includeCompatible: true));
      expect(r.map((d) => d.id), ['1', '2']);
    });
  });
}
