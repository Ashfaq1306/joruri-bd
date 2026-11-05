import 'package:joruri_core/joruri_core.dart';
import 'package:test/test.dart';

void main() {
  final stations = [
    Station.fromJson({'id': 'a', 'name': 'Savar Model Thana', 'nameBn': 'সাভার মডেল থানা', 'districtId': 'dhaka', 'phone': '+8801320089377'}),
    Station.fromJson({'id': 'b', 'name': 'Ramna Model Thana', 'nameBn': 'রমনা মডেল থানা', 'districtId': 'dhaka', 'phone': '+8801320039492', 'unit': 'Dhaka Metropolitan Police (DMP)'}),
    Station.fromJson({'id': 'c', 'name': 'Narayanganj Sadar Model Thana', 'districtId': 'narayanganj', 'phone': '+8801320090377'}),
    Station.fromJson({'id': 'd', 'name': 'Fatullah Model Thana', 'districtId': 'narayanganj', 'phone': '+8801320090403'}),
  ];

  test('parses with defaults: police, open 24 hours', () {
    final s = stations.first;
    expect(s.service, StationService.police);
    expect(s.open24h, isTrue);
    expect(s.displayName('bn'), 'সাভার মডেল থানা');
    expect(s.displayName('en'), 'Savar Model Thana');
    expect(Station.fromJson(s.toJson()).phone, s.phone);
  });

  test('district filter; metropolitan and sadar stations first', () {
    expect(searchStations(stations, districtId: 'dhaka').map((s) => s.id), ['b', 'a']);
    expect(searchStations(stations, districtId: 'narayanganj').map((s) => s.id), ['c', 'd']);
  });

  test('fire: the district\'s own station first, offices last, held numbers stay blank', () {
    final fire = [
      Station.fromJson({'id': 'o', 'name': 'Deputy Assistant Director, Narayanganj Zone-1', 'districtId': 'narayanganj', 'phone': '+8801901020710', 'service': 'fire', 'office': true}),
      Station.fromJson({'id': 'f', 'name': 'Fatullah Fire Station', 'districtId': 'narayanganj', 'phone': '+8801901020838', 'service': 'fire'}),
      Station.fromJson({'id': 'n', 'name': 'Narayanganj Fire Station', 'districtId': 'narayanganj', 'phone': '+8801901020828', 'service': 'fire'}),
      Station.fromJson({'id': 'h', 'name': 'Agrabad Fire Station', 'districtId': 'chattogram', 'phone': '', 'service': 'fire', 'needsCheck': 'Printed with 12 digits.'}),
    ];
    expect(searchStations(fire, districtId: 'narayanganj').map((s) => s.id), ['n', 'f', 'o']);
    final held = fire.last;
    expect(held.service, StationService.fire);
    expect(held.allPhones, isEmpty);
    expect(Station.fromJson(held.toJson()).needsCheck, 'Printed with 12 digits.');
    expect(Station.fromJson(fire.first.toJson()).office, isTrue);
  });

  test('search in Bangla, English and by district name', () {
    expect(searchStations(stations, text: 'রমনা').single.id, 'b');
    expect(searchStations(stations, text: 'fatul').single.id, 'd');
    expect(searchStations(stations, text: 'নারায়ণগঞ্জ').length, 2);
  });
}
