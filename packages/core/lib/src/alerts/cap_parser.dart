import 'package:xml/xml.dart';

import '../geo/bd_locations.dart';
import '../localized_text.dart';
import 'hazard_alert.dart';

/// Reads one Common Alerting Protocol (CAP 1.2) message, as published by the
/// Bangladesh Meteorological Department at cap.bmd.gov.bd/api/cap/{id}.xml.
/// BMD sends each warning in English and Bangla (two `info` blocks).
///
/// Returns null for tests, exercises, cancellations and anything unreadable.
HazardAlert? parseCapAlert(String xmlText, {String source = AlertSource.bmd}) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlText);
  } catch (_) {
    return null;
  }
  final alert = doc.rootElement;
  if (alert.localName != 'alert') return null;
  String text(XmlElement e, String name) => _child(e, name)?.innerText.trim() ?? '';

  final id = text(alert, 'identifier');
  if (id.isEmpty) return null;
  if (text(alert, 'status').toLowerCase() != 'actual') return null;
  if (text(alert, 'msgType').toLowerCase() == 'cancel') return null;
  final sent = DateTime.tryParse(text(alert, 'sent'))?.toUtc();
  if (sent == null) return null;

  final infos = alert.childElements.where((e) => e.localName == 'info').toList();
  if (infos.isEmpty) return null;
  XmlElement? byLang(String prefix) {
    for (final i in infos) {
      if (text(i, 'language').toLowerCase().startsWith(prefix)) return i;
    }
    return null;
  }

  final en = byLang('en') ?? infos.first;
  final bn = byLang('bn');
  LocalizedText both(String name) => LocalizedText(en: text(en, name), bn: bn == null ? '' : text(bn, name));
  String areas(XmlElement? info) {
    if (info == null) return '';
    final names = <String>[];
    for (final a in info.childElements.where((e) => e.localName == 'area')) {
      final d = text(a, 'areaDesc');
      if (d.isNotEmpty && !names.contains(d)) names.add(d);
    }
    return names.join(', ');
  }

  // Area: polygons and circles of every <area>, plus the place names.
  final polygons = <List<(double, double)>>[];
  final circles = <(double, double, double)>[];
  for (final a in en.childElements.where((e) => e.localName == 'area')) {
    for (final p in a.childElements.where((e) => e.localName == 'polygon')) {
      final poly = _pairs(p.innerText);
      if (poly.length >= 3) polygons.add(poly);
    }
    for (final c in a.childElements.where((e) => e.localName == 'circle')) {
      final parts = c.innerText.trim().split(RegExp(r'\s+'));
      final centre = _pairs(parts.first);
      final r = parts.length > 1 ? double.tryParse(parts[1]) : null;
      if (centre.length == 1 && r != null) circles.add((centre.first.$1, centre.first.$2, r));
    }
  }
  final areaEn = areas(en);
  final instructionEn = text(en, 'instruction');
  final districts = <String>{
    ...districtsInArea(polygons: polygons, circles: circles),
    ...districtsNamedIn(areaEn),
    ...districtsNamedIn(instructionEn),
  };
  final nationwide = _nationwide.hasMatch(areaEn.toLowerCase());

  final event = text(en, 'event');
  final headline = both('headline');
  final hazard = hazardOf(event, headline.en, instructionEn);
  final signal = hazard == Hazard.cyclone ? stormSignal(instructionEn) ?? stormSignal(text(en, 'description')) : null;
  var level = AlertLevel.fromCapSeverity(text(en, 'severity'));
  if (signal != null) level = levelForSignal(signal);

  return HazardAlert(
    id: '$source-$id',
    source: source,
    hazard: hazard,
    level: level,
    headline: headline.isEmpty ? LocalizedText(en: event, bn: bn == null ? '' : text(bn, 'event')) : headline,
    description: both('description'),
    instruction: both('instruction'),
    areaText: LocalizedText(en: areaEn, bn: areas(bn)),
    districts: nationwide ? const [] : (districts.toList()..sort()),
    nationwide: nationwide,
    sent: sent,
    effective: DateTime.tryParse(text(en, 'effective'))?.toUtc(),
    expires: DateTime.tryParse(text(en, 'expires'))?.toUtc(),
    web: text(en, 'web'),
    signal: signal,
  );
}

/// Identifiers this CAP message replaces (`references`: "sender,id,sent …").
Set<String> capReferences(String xmlText) {
  final m = RegExp(r'<(?:\w+:)?references>([\s\S]*?)</(?:\w+:)?references>').firstMatch(xmlText);
  if (m == null) return const {};
  return {
    for (final ref in m.group(1)!.trim().split(RegExp(r'\s+')))
      if (ref.split(',').length >= 2) ref.split(',')[1],
  };
}

/// Links to the CAP messages in BMD's RSS feed (cap.bmd.gov.bd/api/cap/rss.xml),
/// newest first, with the time each was published.
List<({String url, DateTime? published})> parseCapFeed(String rssText) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(rssText);
  } catch (_) {
    return const [];
  }
  final out = <({String url, DateTime? published})>[];
  for (final item in doc.findAllElements('item')) {
    final link = item.getElement('link')?.innerText.trim() ?? '';
    if (!link.endsWith('.xml')) continue;
    out.add((url: link, published: _rfc822(item.getElement('pubDate')?.innerText.trim() ?? '')));
  }
  return out;
}

XmlElement? _child(XmlElement e, String name) {
  for (final c in e.childElements) {
    if (c.localName == name) return c;
  }
  return null;
}

/// "26.31,88.37 26.01,88.35 …" → [(26.31, 88.37), …]
List<(double, double)> _pairs(String s) {
  final out = <(double, double)>[];
  for (final pair in s.trim().split(RegExp(r'\s+'))) {
    final xy = pair.split(',');
    if (xy.length != 2) continue;
    final lat = double.tryParse(xy[0]), lon = double.tryParse(xy[1]);
    if (lat != null && lon != null) out.add((lat, lon));
  }
  return out;
}

final _nationwide = RegExp(r'\b(all (over the )?(country|divisions)|whole country|entire country|across the country|countrywide|nationwide)\b');

/// The kind of danger, from the CAP `event` ("Rain", "Wind", "Heat" …) and headline.
Hazard hazardOf(String event, String headline, [String instruction = '']) {
  final e = event.toLowerCase();
  final all = '$e ${headline.toLowerCase()}';
  bool has(String s, String w) => s.contains(w);
  if (has(all, 'tsunami')) return Hazard.tsunami;
  if (has(all, 'earthquake')) return Hazard.earthquake;
  if (has(all, 'landslide')) return Hazard.landslide;
  if (has(all, 'flood') || has(all, 'surge')) return Hazard.flood;
  if (has(all, 'cyclon') || has(all, 'depression') || has(all, 'low pressure')) {
    return has(e, 'rain') ? Hazard.rain : Hazard.cyclone;
  }
  if (has(e, 'rain') || has(all, 'rainfall')) return Hazard.rain;
  if (has(all, 'heat')) return Hazard.heat;
  if (has(all, 'cold')) return Hazard.cold;
  if (has(all, 'fog')) return Hazard.fog;
  if (has(all, 'thunder') || has(all, "nor'wester") || has(all, 'norwester') || has(all, 'squall') ||
      has(all, 'lightning') || has(all, 'hail') || has(all, 'storm') || has(all, 'tornado')) {
    return Hazard.storm;
  }
  if (has(e, 'wind')) return RegExp(r'signal', caseSensitive: false).hasMatch(instruction) ? Hazard.cyclone : Hazard.storm;
  return Hazard.other;
}

const _numberWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
};

/// Highest storm signal number named in a bulletin, e.g. "great danger
/// signal number ten (10)" → 10, "signal no. 7" → 7.
int? stormSignal(String text) {
  int? best;
  final re = RegExp(r'signal\s*(?:no\.?|number|nos?\.)?\s*([a-z]+|\d{1,2})?\s*\(?\s*(\d{1,2})?', caseSensitive: false);
  for (final m in re.allMatches(text)) {
    // "lower the danger signal number seven and hoist …": not the current one.
    final before = text.substring(m.start < 45 ? 0 : m.start - 45, m.start).toLowerCase();
    if (before.contains('lower') && !before.contains('hoist')) continue;
    final digits = int.tryParse(m.group(2) ?? '') ?? int.tryParse(m.group(1) ?? '');
    final n = digits ?? _numberWords[(m.group(1) ?? '').toLowerCase()];
    if (n != null && n >= 1 && n <= 11 && (best == null || n > best)) best = n;
  }
  return best;
}

/// Bangladesh maritime port signals: 1–2 distant, 3–4 local caution and
/// warning, 5–7 danger, 8–10 great danger, 11 communication failure.
AlertLevel levelForSignal(int signal) => switch (signal) {
      <= 2 => AlertLevel.advisory,
      <= 4 => AlertLevel.watch,
      <= 7 => AlertLevel.warning,
      _ => AlertLevel.emergency,
    };

/// Other spellings of district names used in bulletins, and the four sea
/// ports (Mongla is in Bagerhat, Payra in Patuakhali).
const _aliases = {
  'chittagong': 'chattogram',
  'ctg': 'chattogram',
  'coxs bazar': 'coxs-bazar',
  'coxsbazar': 'coxs-bazar',
  'cox bazar': 'coxs-bazar',
  'mongla': 'bagerhat',
  'payra': 'patuakhali',
  'barisal': 'barishal',
  'comilla': 'cumilla',
  'jessore': 'jashore',
  'bogra': 'bogura',
  'chapai nawabganj': 'chapainawabganj',
  'chapainawabgonj': 'chapainawabganj',
  'jhalakathi': 'jhalokati',
  'jhalakati': 'jhalokati',
  'maulvibazar': 'moulvibazar',
  'moulvi bazar': 'moulvibazar',
  'netrakona': 'netrokona',
  'laxmipur': 'lakshmipur',
  'khagrachari': 'khagrachhari',
  'rangamati': 'rangamati',
  'narshingdi': 'narsingdi',
  'kishorganj': 'kishoreganj',
  'brahmanbaria': 'brahmanbaria',
  'hatiya': 'noakhali',
  'sandwip': 'chattogram',
  'kutubdia': 'coxs-bazar',
  'moheshkhali': 'coxs-bazar',
  'maheshkhali': 'coxs-bazar',
  'teknaf': 'coxs-bazar',
  'st martin': 'coxs-bazar',
};

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp("['’`]"), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

/// Districts named in English text. A name followed by "division(s)" — or
/// in a list ending with "divisions" — means every district of that division.
List<String> districtsNamedIn(String text) {
  if (text.trim().isEmpty) return const [];
  final out = <String>{};
  // Each clause separately, so "Rangpur, Mymensingh and Sylhet divisions"
  // reads as three divisions but "Dhaka district" stays one district.
  for (final clause in text.split(RegExp(r'[.;:\n]'))) {
    final t = ' ${_norm(clause)} ';
    final divisionList = RegExp(r'\bdivisions?\b').hasMatch(t) && !RegExp(r'\bdistricts?\b').hasMatch(t);
    for (final div in BdLocations.divisions) {
      final name = _norm(div.en);
      final names = [name, if (name == 'chattogram') 'chittagong', if (name == 'barishal') 'barisal'];
      for (final n in names) {
        final asDivision = RegExp('\\b$n( and [a-z ]+)? divisions?\\b').hasMatch(t) ||
            (divisionList && RegExp('\\b$n\\b').hasMatch(t));
        if (asDivision) {
          out.addAll(BdLocations.districts.where((d) => d.divisionId == div.id).map((d) => d.id));
        }
      }
    }
    if (divisionList) continue;
    for (final d in BdLocations.districts) {
      if (RegExp('\\b${_norm(d.en)}\\b').hasMatch(t)) out.add(d.id);
    }
    for (final MapEntry(key: alias, value: id) in _aliases.entries) {
      if (RegExp('\\b$alias\\b').hasMatch(t)) out.add(id);
    }
  }
  return out.toList()..sort();
}

const _months = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};

/// "Sun, 25 Oct 2026 05:28:00 +0000" → UTC time.
DateTime? _rfc822(String s) {
  final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([+-])(\d{2})(\d{2})').firstMatch(s);
  if (m == null) return null;
  final month = _months[m.group(2)!.toLowerCase()];
  if (month == null) return null;
  final t = DateTime.utc(int.parse(m.group(3)!), month, int.parse(m.group(1)!), int.parse(m.group(4)!),
      int.parse(m.group(5)!), int.parse(m.group(6)!));
  final offset = Duration(hours: int.parse(m.group(8)!), minutes: int.parse(m.group(9)!));
  return m.group(7) == '+' ? t.subtract(offset) : t.add(offset);
}
