import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/features/directory/data/places_repository.dart';

void main() {
  const dghs = {
    'id': 'dghs-60',
    'name': 'Dhamrai Upazila Health Complex',
    'nameBn': 'ধামরাই উপজেলা স্বাস্থ্য কমপ্লেক্স',
    'kind': 'Upazila Health Complex',
    'kindBn': 'উপজেলা স্বাস্থ্য কমপ্লেক্স',
    'government': true,
    'districtId': 'dhaka',
    'area': 'Dhamrai',
    'phone': '+8801810158701',
    'otherPhones': ['+8801730324400'],
    'lat': 23.9136,
    'lng': 90.2275,
    'emergency': true,
    'feeChart': 'govt-basic',
  };
  final charts = <String, List<dynamic>>{
    'govt-basic': [
      {'name': 'CBC (TC, DC, ESR, Hb)', 'aliases': ['CBC', 'সিবিসি'], 'priceBdt': 150},
    ],
  };

  test('a DGHS hospital reads every new field and shows its Bangla name', () {
    final h = Hospital.fromJson(withFeeChart(Map<String, dynamic>.from(dghs), charts));
    expect(h.displayName('bn'), 'ধামরাই উপজেলা স্বাস্থ্য কমপ্লেক্স');
    expect(h.displayName('en'), 'Dhamrai Upazila Health Complex');
    expect(h.government, isTrue);
    expect(h.allPhones, ['+8801810158701', '+8801730324400']);
    expect(h.latitude, closeTo(23.9136, 1e-6));
    expect(h.searchText, contains('dhamrai'));
  });

  test('the shared government fee chart fills in tests and prices', () {
    final h = Hospital.fromJson(withFeeChart(Map<String, dynamic>.from(dghs), charts));
    expect(h.tests.single.priceBdt, 150);
    final offers = findTest([h], 'সিবিসি', const PlaceFilter());
    expect(offers, hasLength(1));
  });

  test("a hospital's own tests win over the chart", () {
    final own = {
      ...dghs,
      'tests': [
        {'name': 'CBC', 'priceBdt': 120},
      ],
    };
    final h = Hospital.fromJson(withFeeChart(own, charts));
    expect(h.tests.single.priceBdt, 120);
  });

  test('a hospital with no phone number is kept, not dropped', () {
    final h = Hospital.fromJson({'id': 'x', 'name': 'Clinic', 'districtId': 'feni'});
    expect(h.phone, '');
    expect(h.allPhones, isEmpty);
  });
}
