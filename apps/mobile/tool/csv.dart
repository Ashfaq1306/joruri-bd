import 'dart:io';

/// Reads a CSV file saved by Excel or Google Sheets (removes the UTF-8 marker).
String readCsvText(File file) {
  final text = file.readAsStringSync();
  return text.startsWith('\uFEFF') ? text.substring(1) : text;
}

/// A CSV table with named columns.
class CsvTable {
  CsvTable(List<List<String>> rows)
      : header = rows.isEmpty ? const [] : rows.first.map((h) => h.trim().toLowerCase().replaceAll(' ', '_')).toList(),
        rows = rows.length <= 1 ? const [] : rows.sublist(1);

  final List<String> header;
  final List<List<String>> rows;

  List<String> missing(List<String> required) => required.where((c) => !header.contains(c)).toList();

  String cell(List<String> row, String name) {
    final i = header.indexOf(name);
    return i >= 0 && i < row.length ? row[i].trim() : '';
  }
}

bool isYes(String v) => const ['yes', 'y', 'true', '1', 'হ্যাঁ', 'হা'].contains(v.trim().toLowerCase());

/// Minimal CSV reader: commas, quoted fields, "" inside quotes, CRLF.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
