// Turns your hospital, test-price and pharmacy spreadsheets into the lists
// the app shows. Save each sheet as "CSV UTF-8", then from apps/mobile run:
//
//   dart run tool/import_places.dart hospitals tool/hospitals.csv tool/hospital_tests.csv
//   dart run tool/import_places.dart pharmacies tool/pharmacies.csv
//
// Templates: tool/hospitals_template.csv, tool/hospital_tests_template.csv,
// tool/pharmacies_template.csv. Rows with a problem are skipped and listed.
import 'dart:convert';
import 'dart:io';

import 'package:joruri_core/joruri_core.dart';

import 'csv.dart';

void main(List<String> args) {
  if (args.length < 2 || !const ['hospitals', 'pharmacies'].contains(args.first)) {
    stderr.writeln('Usage:\n'
        '  dart run tool/import_places.dart hospitals <hospitals.csv> [hospital_tests.csv]\n'
        '  dart run tool/import_places.dart pharmacies <pharmacies.csv>');
    exitCode = 64;
    return;
  }
  final problems = <String>[];
  if (args.first == 'hospitals') {
    final hospitals = _hospitals(_read(args[1]), problems);
    if (args.length > 2) _attachTests(hospitals, _read(args[2]), problems);
    _write('assets/seed/hospitals.json', 'hospitals', hospitals.values.map((h) => h.toJson()).toList());
    stdout.writeln('Imported ${hospitals.length} hospital(s), '
        '${hospitals.values.fold<int>(0, (n, h) => n + h.tests.length)} test price(s).');
  } else {
    final pharmacies = _pharmacies(_read(args[1]), problems);
    _write('assets/seed/pharmacies.json', 'pharmacies', pharmacies.map((p) => p.toJson()).toList());
    stdout.writeln('Imported ${pharmacies.length} pharmacy(ies).');
  }
  if (problems.isNotEmpty) {
    stdout.writeln('\nSkipped ${problems.length} row(s). Fix them in the spreadsheet and run again:');
    for (final p in problems) {
      stdout.writeln('  $p');
    }
  }
}

class _Sheet {
  _Sheet(this.name, List<List<String>> rows)
      : header = rows.isEmpty ? const [] : rows.first.map((h) => h.trim().toLowerCase().replaceAll(' ', '_')).toList(),
        rows = rows.length > 1 ? rows.sublist(1) : const [];

  final String name;
  final List<String> header;
  final List<List<String>> rows;

  String cell(List<String> row, String column) {
    final i = header.indexOf(column);
    return i >= 0 && i < row.length ? row[i].trim() : '';
  }

  void require(List<String> columns) {
    final missing = columns.where((c) => !header.contains(c)).toList();
    if (missing.isNotEmpty) {
      stderr.writeln('$name: missing column(s) ${missing.join(', ')}');
      exit(65);
    }
  }
}

_Sheet _read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(66);
  }
  var text = file.readAsStringSync();
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  return _Sheet(path, parseCsv(text));
}

bool _yes(String v) => const ['yes', 'y', 'true', '1', 'হ্যাঁ', 'হা'].contains(v.trim().toLowerCase());

bool _blank(List<String> row) => row.every((c) => c.trim().isEmpty);

/// Hospital phones are often landlines, so any 6–15 digit number is accepted.
String? _phone(String v) => v.isEmpty ? null : BdPhone.normalizeContact(v);

Map<String, Hospital> _hospitals(_Sheet sheet, List<String> problems) {
  sheet.require(['id', 'name', 'district', 'phone']);
  final out = <String, Hospital>{};
  for (var i = 0; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    if (_blank(r)) continue;
    final id = sheet.cell(r, 'id');
    final name = sheet.cell(r, 'name');
    final district = BdLocations.findDistrict(sheet.cell(r, 'district'));
    final phone = _phone(sheet.cell(r, 'phone'));
    final reasons = [
      if (id.isEmpty) 'no id',
      if (out.containsKey(id)) 'id "$id" used twice',
      if (name.isEmpty) 'no name',
      if (district == null) 'district "${sheet.cell(r, 'district')}" not found',
      if (phone == null) 'phone "${sheet.cell(r, 'phone')}" not valid',
    ];
    if (reasons.isNotEmpty) {
      problems.add('${sheet.name} row ${i + 2}: ${reasons.join('; ')}');
      continue;
    }
    out[id] = Hospital(
      id: id,
      name: name,
      districtId: district!.id,
      phone: phone!,
      area: sheet.cell(r, 'area'),
      address: sheet.cell(r, 'address'),
      emergencyPhone: _phone(sheet.cell(r, 'emergency_phone')),
      emergency: _yes(sheet.cell(r, 'emergency')),
      bloodBank: _yes(sheet.cell(r, 'blood_bank')),
      ambulance: _yes(sheet.cell(r, 'ambulance')),
      icu: _yes(sheet.cell(r, 'icu')),
      open24h: _yes(sheet.cell(r, 'open_24h')),
      pricesCheckedOn: sheet.cell(r, 'prices_checked_on').isEmpty ? null : sheet.cell(r, 'prices_checked_on'),
      verified: _yes(sheet.cell(r, 'verified')),
    );
  }
  return out;
}

void _attachTests(Map<String, Hospital> hospitals, _Sheet sheet, List<String> problems) {
  sheet.require(['hospital_id', 'test']);
  final tests = <String, List<TestPrice>>{};
  for (var i = 0; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    if (_blank(r)) continue;
    final id = sheet.cell(r, 'hospital_id');
    final name = sheet.cell(r, 'test');
    final priceText = sheet.cell(r, 'price').replaceAll(RegExp(r'[^0-9০-৯]'), '');
    final price = priceText.isEmpty ? null : int.tryParse(BdPhone.clean(priceText));
    final reasons = [
      if (!hospitals.containsKey(id)) 'hospital_id "$id" is not in the hospitals sheet',
      if (name.isEmpty) 'no test name',
    ];
    if (reasons.isNotEmpty) {
      problems.add('${sheet.name} row ${i + 2}: ${reasons.join('; ')}');
      continue;
    }
    (tests[id] ??= []).add(TestPrice(
      name: name,
      aliases: sheet.cell(r, 'aliases').split('|').map((a) => a.trim()).where((a) => a.isNotEmpty).toList(),
      priceBdt: price,
      note: sheet.cell(r, 'note'),
    ));
  }
  for (final entry in tests.entries) {
    final h = hospitals[entry.key]!;
    hospitals[entry.key] = Hospital(
      id: h.id,
      name: h.name,
      districtId: h.districtId,
      phone: h.phone,
      area: h.area,
      address: h.address,
      emergencyPhone: h.emergencyPhone,
      emergency: h.emergency,
      bloodBank: h.bloodBank,
      ambulance: h.ambulance,
      icu: h.icu,
      open24h: h.open24h,
      pricesCheckedOn: h.pricesCheckedOn,
      verified: h.verified,
      tests: entry.value,
    );
  }
}

List<Pharmacy> _pharmacies(_Sheet sheet, List<String> problems) {
  sheet.require(['name', 'district', 'phone']);
  final out = <Pharmacy>[];
  for (var i = 0; i < sheet.rows.length; i++) {
    final r = sheet.rows[i];
    if (_blank(r)) continue;
    final name = sheet.cell(r, 'name');
    final district = BdLocations.findDistrict(sheet.cell(r, 'district'));
    final phone = _phone(sheet.cell(r, 'phone'));
    final reasons = [
      if (name.isEmpty) 'no name',
      if (district == null) 'district "${sheet.cell(r, 'district')}" not found',
      if (phone == null) 'phone "${sheet.cell(r, 'phone')}" not valid',
    ];
    if (reasons.isNotEmpty) {
      problems.add('${sheet.name} row ${i + 2}: ${reasons.join('; ')}');
      continue;
    }
    out.add(Pharmacy(
      id: 'p${out.length + 1}',
      name: name,
      districtId: district!.id,
      phone: phone!,
      area: sheet.cell(r, 'area'),
      address: sheet.cell(r, 'address'),
      open24h: _yes(sheet.cell(r, 'open_24h')),
      verified: _yes(sheet.cell(r, 'verified')),
    ));
  }
  return out;
}

void _write(String path, String key, List<Map<String, dynamic>> items) {
  final json = const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'updatedAt': DateTime.now().toIso8601String().substring(0, 10),
    key: items,
  });
  File(path).writeAsStringSync('$json\n');
}
