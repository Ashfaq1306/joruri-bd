// Turns your donor spreadsheet into the list the app shows.
//
//   1. In Excel or Google Sheets, fill tool/donors_template.csv
//      (one donor per row) and save it as "CSV UTF-8".
//   2. From apps/mobile run:  dart run tool/import_donors.dart path/to/donors.csv
//   3. Rebuild the app.
//
// Columns (header row required, any order):
//   name, blood_group, phone, district, consent      required
//   area, available, last_donation (YYYY-MM-DD), verified   optional
//
// consent must be "yes": only donors who agreed to have their number shown
// are imported. Rows with a problem are skipped and listed, never guessed.
import 'dart:convert';
import 'dart:io';

import 'package:joruri_core/joruri_core.dart';

import 'csv.dart';

const _output = 'assets/seed/donors.json';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/import_donors.dart <donors.csv>');
    exitCode = 64;
    return;
  }
  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('File not found: ${args.first}');
    exitCode = 66;
    return;
  }

  final text = readCsvText(file);
  final rows = parseCsv(text);
  if (rows.isEmpty) {
    stderr.writeln('The file is empty.');
    exitCode = 65;
    return;
  }

  final header = rows.first.map((h) => h.trim().toLowerCase().replaceAll(' ', '_')).toList();
  int col(String name) => header.indexOf(name);
  const required = ['name', 'blood_group', 'phone', 'district', 'consent'];
  final missing = required.where((c) => col(c) < 0).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Missing column(s): ${missing.join(', ')}');
    exitCode = 65;
    return;
  }

  String cell(List<String> row, String name) {
    final i = col(name);
    return i >= 0 && i < row.length ? row[i].trim() : '';
  }

  bool yes(String v) => const ['yes', 'y', 'true', '1', 'হ্যাঁ', 'হা'].contains(v.trim().toLowerCase());

  final donors = <Donor>[];
  final problems = <String>[];
  final seenPhones = <String>{};

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final line = i + 1;
    if (row.every((c) => c.trim().isEmpty)) continue;

    final name = cell(row, 'name');
    final group = BloodGroup.parse(cell(row, 'blood_group'));
    final phone = BdPhone.normalizeMobile(cell(row, 'phone'));
    final district = BdLocations.findDistrict(cell(row, 'district'));
    final consent = yes(cell(row, 'consent'));

    final reasons = [
      if (name.isEmpty) 'no name',
      if (group == null) 'blood group "${cell(row, 'blood_group')}" not recognised',
      if (phone == null) 'phone "${cell(row, 'phone')}" is not a valid Bangladeshi mobile',
      if (district == null) 'district "${cell(row, 'district')}" not found',
      if (!consent) 'consent is not "yes"',
    ];
    if (reasons.isNotEmpty) {
      problems.add('Row $line: ${reasons.join('; ')}');
      continue;
    }
    if (!seenPhones.add(phone!)) {
      problems.add('Row $line: same phone as an earlier row, skipped');
      continue;
    }

    final availableText = cell(row, 'available');
    donors.add(Donor(
      id: phone.substring(1),
      name: name,
      bloodGroup: group!,
      phone: phone,
      districtId: district!.id,
      area: cell(row, 'area'),
      available: availableText.isEmpty || yes(availableText),
      lastDonation: DateTime.tryParse(cell(row, 'last_donation')),
      verified: yes(cell(row, 'verified')),
      shareConsent: true,
    ));
  }

  final out = const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'updatedAt': DateTime.now().toIso8601String().substring(0, 10),
    'donors': donors.map((d) => d.toJson()).toList(),
  });
  File(_output).writeAsStringSync('$out\n');

  stdout.writeln('Imported ${donors.length} donor(s) into $_output');
  if (problems.isNotEmpty) {
    stdout.writeln('\nSkipped ${problems.length} row(s). Fix them in the spreadsheet and run again:');
    for (final p in problems) {
      stdout.writeln('  $p');
    }
  }
}
