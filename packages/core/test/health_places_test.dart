import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

Hospital _h(String id, String district, List<TestPrice> tests, {String area = ''}) =>
    Hospital(id: id, name: 'Hospital $id', districtId: district, phone: '0200000000', area: area, tests: tests);

void main() {
  final hospitals = [
    _h('a', 'dhaka', [const TestPrice(name: 'CBC', aliases: ['সিবিসি'], priceBdt: 500)], area: 'Mirpur'),
    _h('b', 'dhaka', [const TestPrice(name: 'CBC', priceBdt: 350)]),
    _h('c', 'dhaka', [const TestPrice(name: 'CBC')]),
    _h('d', 'sylhet', [const TestPrice(name: 'CBC', priceBdt: 200)]),
  ];

  test('cheapest first, unpriced last, location respected', () {
    final r = findTest(hospitals, 'cbc', const PlaceFilter(districtId: 'dhaka'));
    expect(r.map((o) => o.hospital.id), ['b', 'a', 'c']);
  });

  test('finds tests by Bangla alias and area', () {
    final r = findTest(hospitals, 'সিবিসি', const PlaceFilter(areaText: 'mir'));
    expect(r.map((o) => o.hospital.id), ['a']);
  });

  test('the text box also matches the hospital name ("CBC at Hospital b")', () {
    final r = findTest(hospitals, 'cbc', const PlaceFilter(areaText: 'hospital b'));
    expect(r.map((o) => o.hospital.id), ['b']);
  });

  test('division filter', () {
    expect(const PlaceFilter(divisionId: 'sylhet').accepts('sylhet', ''), isTrue);
    expect(const PlaceFilter(divisionId: 'sylhet').accepts('dhaka', ''), isFalse);
    // Name search must not be blocked by the district check (bug in 1.2.0).
    expect(const PlaceFilter(areaText: 'x').acceptsDistrict('dhaka'), isTrue);
    expect(const PlaceFilter(districtId: 'dhaka', areaText: 'ramna').acceptsDistrict('dhaka'), isTrue);
    expect(const PlaceFilter(divisionId: 'dhaka', areaText: 'x').acceptsDistrict('gazipur'), isTrue);
    expect(const PlaceFilter(divisionId: 'sylhet', areaText: 'x').acceptsDistrict('dhaka'), isFalse);
  });
}
