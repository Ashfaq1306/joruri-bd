import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_core/joruri_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = PlacesRepository(rootBundle);

  test('every district has a readable DGDA pharmacy file', () async {
    var total = 0;
    for (final d in BdLocations.districts) {
      final list = await repo.registerPharmacies(d.id);
      expect(list, isNotEmpty, reason: d.id);
      expect(list.every((p) => p.districtId == d.id && p.source == 'DGDA' && p.licenceValidUpto != null), isTrue);
      total += list.length;
    }
    expect(total, greaterThan(100000));
  });

  test('bundled medicine prices load and search', () async {
    final m = await repo.medicines();
    expect(m.items.length, greaterThan(30000));
    expect(m.downloadedOn, isNotEmpty);
    expect(searchMedicines(m.items, 'paracetamol'), isNotEmpty);
  });

  test('every district has police stations with a valid OC mobile number', () async {
    final all = await repo.policeStations();
    expect(all.length, greaterThan(600));
    expect({for (final s in all) s.id}.length, all.length, reason: 'ids are unique');
    expect({for (final s in all) s.phone}.length, all.length, reason: 'each number belongs to one station');
    for (final d in BdLocations.districts) {
      expect(all.where((s) => s.districtId == d.id), isNotEmpty, reason: d.id);
    }
    for (final s in all) {
      expect(s.phone, matches(RegExp(r'^\+8801[3-9]\d{8}$')), reason: s.name);
      expect(s.nameBn, isNotEmpty, reason: s.name);
      expect(BdLocations.district(s.districtId), isNotNull, reason: s.name);
    }
    final ramna = all.firstWhere((s) => s.name == 'Ramna Model Thana');
    expect(ramna.phone, '+8801320039492');
    expect(ramna.email, 'ocramna@dmp.gov.bd');
  });
}
