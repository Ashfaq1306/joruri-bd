import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';

void main() {
  final json = jsonDecode(File('assets/seed/fire_stations.json').readAsStringSync()) as Map<String, dynamic>;
  final all = [for (final x in json['fireStations'] as List) Station.fromJson(x as Map<String, dynamic>)];

  test('bundled fire stations: every district, fire service, real districts', () {
    expect(all.length, greaterThan(600));
    expect(all.every((s) => s.service == StationService.fire), isTrue);
    expect(all.every((s) => BdLocations.district(s.districtId) != null), isTrue);
    final districts = {for (final s in all) if (!s.office) s.districtId};
    expect(districts.length, 64, reason: 'every district has at least one fire station');
    expect({for (final s in all) s.id}.length, all.length, reason: 'ids are unique');
  });

  test('numbers: valid Bangladeshi numbers, never one number on two entries', () {
    final phones = [for (final s in all) if (s.phone.isNotEmpty) s.phone];
    expect(phones.every((p) => RegExp(r'^\+8801[3-9]\d{8}$').hasMatch(p)), isTrue);
    expect(phones.toSet().length, phones.length);
    // A misprinted number is left blank, with the reason, never guessed.
    final held = all.where((s) => s.phone.isEmpty).toList();
    expect(held, isNotEmpty);
    expect(held.every((s) => s.needsCheck.isNotEmpty), isTrue);
  });

  test('district search: the district\'s own station first, offices last', () {
    final found = searchStations(all, districtId: 'narayanganj');
    expect(found.first.name, 'Narayanganj Fire Station');
    expect(found.last.office, isTrue);
    expect(searchStations(all, text: 'ফতুল্লা').single.name, 'Fatullah Fire Station');
  });
}
