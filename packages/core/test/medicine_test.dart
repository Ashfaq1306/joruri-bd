import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

Medicine _m(String brand, String generic, double? price, {String form = 'Tablet', String strength = '500 mg'}) => Medicine(
      brand: brand,
      generic: generic,
      strength: strength,
      form: form,
      company: 'Co',
      packs: [if (price != null) MedicinePack('10 x 10', price)],
    );

void main() {
  final all = [
    _m('Napa', 'Paracetamol', 1.2),
    _m('Napa Extra', 'Paracetamol + Caffeine', 2.5, strength: '500 mg + 65 mg'),
    _m('Ace', 'Paracetamol', 1.0),
    _m('Renapa', 'Paracetamol', null),
    _m('Napa Syrup', 'Paracetamol', 35, form: 'Syrup', strength: '120 mg/5 ml'),
  ];

  test('brand prefix first, then brand contains, then generic by price', () {
    final r = searchMedicines(all, 'napa').map((m) => m.brand).toList();
    expect(r.take(3), ['Napa', 'Napa Extra', 'Napa Syrup']);
    expect(r[3], 'Renapa');
  });

  test('generic search lists cheapest first, unpriced last', () {
    final r = searchMedicines(all, 'paracetamol').map((m) => m.brand).toList();
    expect(r.first, 'Ace');
    expect(r.last, 'Renapa');
  });

  test('same medicine = same generic, strength and form', () {
    expect(sameMedicine(all, all.first).map((m) => m.brand), ['Ace', 'Napa', 'Renapa']);
  });

  test('compact row with company index', () {
    final m = Medicine.fromRow(['Napa', 'Paracetamol', '500 mg', 'Tablet', 1, '001-0001-001', [['10 x 10', 1.2]]], ['A', 'Beximco']);
    expect(m.company, 'Beximco');
    expect(m.lowestPrice, 1.2);
  });

  test('pharmacy licence validity from register date', () {
    final p = Pharmacy.fromJson({'id': 'x', 'name': 'P', 'districtId': 'dhaka', 'validUpto': '2026-11-03'});
    expect(p.licenceValidOn(DateTime(2026, 11, 3)), isTrue);
    expect(p.licenceValidOn(DateTime(2026, 11, 4)), isFalse);
    expect(p.hasPhone, isFalse);
    expect(Pharmacy.fromJson(p.toJson()).licenceValidUpto, DateTime(2026, 11, 3));
  });
}
