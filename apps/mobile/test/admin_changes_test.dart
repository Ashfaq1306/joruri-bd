import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/features/directory/data/content_cache.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';

/// Changes made on the admin website to the built-in DGDA lists reach the
/// medicine search and the pharmacy list.
class _Repo extends PlacesRepository {
  _Repo() : super(_NoBundle());

  @override
  Future<MedicineList> medicines() async => MedicineList([
        Medicine(brand: 'Napa', generic: 'Paracetamol', strength: '500 mg', form: 'Tablet', company: 'Beximco', dar: '1',
            packs: const [MedicinePack('10 x 10', 1.2)]),
        Medicine(brand: 'Ace', generic: 'Paracetamol', strength: '500 mg', form: 'Tablet', company: 'Square', dar: '2'),
      ], '2026-11-03');

  @override
  Future<List<Pharmacy>> pharmacies() async => const [];

  @override
  Future<List<Pharmacy>> registerPharmacies(String districtId) async => const [
        Pharmacy(id: 'dgda-1', name: 'Open Shop', districtId: 'dhaka', phone: '', licence: 'DHK-1'),
        Pharmacy(id: 'dgda-2', name: 'Closed Shop', districtId: 'dhaka', phone: '', licence: 'DHK-2'),
        Pharmacy(id: 'dgda-3', name: 'Corrected Shop', districtId: 'dhaka', phone: '', licence: 'DHK-3'),
      ];
}

class _NoBundle extends Fake implements AssetBundle {}

void main() {
  ProviderContainer container(Map<String, dynamic>? cache) {
    final c = ProviderContainer(overrides: [
      placesRepositoryProvider.overrideWithValue(_Repo()),
      cachedContentProvider.overrideWith((ref) async => cache),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no admin changes: the DGDA lists as built in', () async {
    final c = container(null);
    expect((await c.read(medicinesProvider.future)).items.length, 2);
    expect((await c.read(districtPharmaciesProvider('dhaka').future)).length, 3);
  });

  test('a corrected price, a hidden brand, a hidden shop and a corrected shop', () async {
    final c = container({
      'medicines': [
        {'id': 'm1', 'replaces': '1|Napa|500 mg|Tablet|Beximco', 'brand': 'Napa', 'generic': 'Paracetamol', 'strength': '500 mg',
          'form': 'Tablet', 'company': 'Beximco', 'packs': [{'pack': '10 x 10', 'price': 1.5}], 'checkedOn': '2026-11-06'},
        {'id': 'm2', 'replaces': '2|Ace|500 mg|Tablet|Square', 'hidden': true},
        {'id': 'm3', 'brand': 'Newpara', 'generic': 'Paracetamol', 'strength': '500 mg', 'form': 'Tablet'},
      ],
      'pharmacies': [
        {'id': 'p-dgda-3', 'name': 'Corrected Shop', 'districtId': 'dhaka', 'phone': '+8801711000000', 'licence': 'DHK-3', 'open24h': true},
      ],
      'pharmacyHides': [
        {'id': 'p-dgda-2', 'licence': 'dhk-2 ', 'districtId': 'dhaka'},
      ],
    });
    final meds = (await c.read(medicinesProvider.future)).items;
    expect(meds.map((m) => m.brand), unorderedEquals(['Napa', 'Newpara']));
    expect(meds.firstWhere((m) => m.brand == 'Napa').lowestPrice, 1.5);
    expect(meds.firstWhere((m) => m.brand == 'Napa').updatedOn, '2026-11-06');

    final shops = await c.read(districtPharmaciesProvider('dhaka').future);
    expect(shops.map((p) => p.name), ['Corrected Shop', 'Open Shop']);
    expect(shops.first.phone, '+8801711000000');
  });
}
