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
}
