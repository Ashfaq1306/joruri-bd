import 'dart:math' as math;

import '../geo/bd_district_points.dart';
import '../geo/bd_locations.dart';
import '../localized_text.dart';

/// The kind of danger a warning is about. Decides the icon, the colour and
/// which "what to do" guides are shown with it.
enum Hazard {
  cyclone,
  flood,
  rain,
  storm,
  heat,
  cold,
  fog,
  landslide,
  earthquake,
  tsunami,
  other;

  static Hazard parse(Object? v) => Hazard.values.firstWhere((h) => h.name == v, orElse: () => Hazard.other);

  /// Ids of the bundled guides that say what to do (assets/seed/guides.json).
  List<String> get guideIds => switch (this) {
        Hazard.cyclone => const ['cyclone', 'flood'],
        Hazard.flood => const ['flood'],
        Hazard.rain => const ['flood', 'landslide', 'lightning'],
        Hazard.storm => const ['severe-storm', 'lightning'],
        Hazard.heat => const ['heatwave'],
        Hazard.cold => const ['coldwave'],
        Hazard.fog => const ['road-accident'],
        Hazard.landslide => const ['landslide'],
        Hazard.earthquake => const ['earthquake', 'building-collapse'],
        Hazard.tsunami => const ['earthquake', 'flood'],
        Hazard.other => const [],
      };
}

/// How serious a warning is. Phones are notified from [watch] up.
enum AlertLevel {
  /// For information: a distant storm, a small far-away earthquake.
  advisory,

  /// Be ready: it may affect you.
  watch,

  /// Take action: it is expected to affect you.
  warning,

  /// Danger to life: act now (great danger signal, strong nearby earthquake).
  emergency;

  static AlertLevel parse(Object? v) =>
      AlertLevel.values.firstWhere((l) => l.name == v, orElse: () => AlertLevel.advisory);

  /// From the CAP `severity` of an official warning.
  static AlertLevel fromCapSeverity(String severity) => switch (severity.trim().toLowerCase()) {
        'extreme' => AlertLevel.emergency,
        'severe' => AlertLevel.warning,
        'moderate' => AlertLevel.watch,
        _ => AlertLevel.advisory,
      };

  bool get notifies => index >= AlertLevel.watch.index;
}

/// Where an alert came from.
abstract final class AlertSource {
  /// Bangladesh Meteorological Department (cap.bmd.gov.bd).
  static const bmd = 'bmd';

  /// US Geological Survey earthquake catalogue (earthquake.usgs.gov).
  static const usgs = 'usgs';

  /// Written by the Joruri BD team on the admin website.
  static const team = 'team';
}

/// Location and size of an earthquake.
class QuakeInfo {
  const QuakeInfo({
    required this.magnitude,
    required this.lat,
    required this.lon,
    this.depthKm,
    this.place = '',
    this.nearestDistrictId = '',
    this.distanceKm,
  });

  factory QuakeInfo.fromJson(Map<String, dynamic> j) => QuakeInfo(
        magnitude: (j['mag'] as num).toDouble(),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        depthKm: (j['depthKm'] as num?)?.toDouble(),
        place: (j['place'] as String?) ?? '',
        nearestDistrictId: (j['nearest'] as String?) ?? '',
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      );

  final double magnitude;
  final double lat;
  final double lon;
  final double? depthKm;

  /// USGS description, e.g. "31 km E of Mawlaik, Burma (Myanmar)".
  final String place;

  /// The Bangladesh district closest to the epicentre, and how far it is.
  final String nearestDistrictId;
  final double? distanceKm;

  Map<String, dynamic> toJson() => {
        'mag': magnitude,
        'lat': lat,
        'lon': lon,
        if (depthKm != null) 'depthKm': depthKm,
        if (place.isNotEmpty) 'place': place,
        if (nearestDistrictId.isNotEmpty) 'nearest': nearestDistrictId,
        if (distanceKm != null) 'distanceKm': distanceKm,
      };
}

/// One warning: from BMD, from the USGS earthquake list, or from the team.
class HazardAlert {
  const HazardAlert({
    required this.id,
    required this.source,
    required this.hazard,
    required this.level,
    required this.headline,
    required this.sent,
    this.description = const LocalizedText(en: '', bn: ''),
    this.instruction = const LocalizedText(en: '', bn: ''),
    this.areaText = const LocalizedText(en: '', bn: ''),
    this.districts = const [],
    this.nationwide = false,
    this.effective,
    this.expires,
    this.web = '',
    this.signal,
    this.quake,
    this.push = true,
  });

  factory HazardAlert.fromJson(Map<String, dynamic> j) => HazardAlert(
        id: j['id'] as String,
        source: (j['source'] as String?) ?? AlertSource.team,
        hazard: Hazard.parse(j['hazard']),
        level: AlertLevel.parse(j['level']),
        headline: LocalizedText.fromJson(j['headline']),
        description: LocalizedText.fromJson(j['description']),
        instruction: LocalizedText.fromJson(j['instruction']),
        areaText: LocalizedText.fromJson(j['area']),
        districts: _districtIds(j),
        nationwide: j['nationwide'] == true,
        sent: _date(j['sent']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        effective: _date(j['effective']),
        expires: _date(j['expires']),
        web: (j['web'] as String?) ?? '',
        signal: (j['signal'] as num?)?.toInt(),
        quake: j['quake'] is Map ? QuakeInfo.fromJson(Map<String, dynamic>.from(j['quake'] as Map)) : null,
        push: j['push'] != false,
      );

  final String id;

  /// [AlertSource.bmd], [AlertSource.usgs] or [AlertSource.team].
  final String source;
  final Hazard hazard;
  final AlertLevel level;
  final LocalizedText headline;
  final LocalizedText description;

  /// What the authority tells people to do.
  final LocalizedText instruction;

  /// The area as the authority wrote it ("Rangpur, Mymensingh and Sylhet divisions").
  final LocalizedText areaText;

  /// Ids of the districts it covers ([BdLocations.districts]).
  final List<String> districts;

  /// True when it covers the whole country.
  final bool nationwide;
  final DateTime sent;
  final DateTime? effective;
  final DateTime? expires;

  /// Link to the authority's page for this warning.
  final String web;

  /// Highest storm signal number in a cyclone bulletin (1–11), if any.
  final int? signal;
  final QuakeInfo? quake;

  /// Team alerts only: false = show in the app without a phone notification.
  final bool push;

  /// How long an alert without an end time stays on screen.
  static const defaultLife = Duration(hours: 24);

  DateTime get endsAt => expires ?? sent.add(defaultLife);

  bool activeAt(DateTime now) => endsAt.isAfter(now);

  bool concerns(String? districtId) => nationwide || (districtId != null && districts.contains(districtId));

  /// Whether a phone set to [districtId] (or to all of Bangladesh) should ring for it.
  bool shouldNotify({String? districtId, bool everywhere = false}) =>
      push && level.notifies && (everywhere ? (nationwide || districts.isNotEmpty) : concerns(districtId));

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'hazard': hazard.name,
        'level': level.name,
        'headline': headline.toJson(),
        if (!description.isEmpty) 'description': description.toJson(),
        if (!instruction.isEmpty) 'instruction': instruction.toJson(),
        if (!areaText.isEmpty) 'area': areaText.toJson(),
        'districts': districts,
        if (nationwide) 'nationwide': true,
        'sent': sent.toUtc().toIso8601String(),
        if (effective != null) 'effective': effective!.toUtc().toIso8601String(),
        if (expires != null) 'expires': expires!.toUtc().toIso8601String(),
        if (web.isNotEmpty) 'web': web,
        if (signal != null) 'signal': signal,
        if (quake != null) 'quake': quake!.toJson(),
        if (!push) 'push': false,
      };

  /// A short copy for a push message (FCM data is limited to 4 KB).
  Map<String, dynamic> toPushJson() {
    String cut(String s, int n) => s.length <= n ? s : '${s.substring(0, n - 1)}…';
    final text = instruction.isEmpty ? description : instruction;
    return {
      ...toJson()..remove('description')..remove('instruction')..remove('area'),
      'description': {'en': cut(text.en, 300), 'bn': cut(text.bn, 220)},
    };
  }

  static List<String> _districtIds(Map<String, dynamic> j) {
    final out = <String>{
      for (final d in (j['districts'] as List? ?? const [])) if (d is String) d,
    };
    // Team alerts may name whole divisions.
    for (final div in (j['divisions'] as List? ?? const [])) {
      out.addAll(BdLocations.districts.where((d) => d.divisionId == div).map((d) => d.id));
    }
    return out.toList(growable: false);
  }

  static DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toUtc() : null;
}

/// Active alerts, most serious and newest first; an alert replaced by a
/// newer bulletin of the same source and hazard is kept (both are shown)
/// unless it has expired.
List<HazardAlert> activeAlerts(Iterable<HazardAlert> all, DateTime now) {
  final seen = <String>{};
  final out = [
    for (final a in all)
      if (a.activeAt(now) && seen.add(a.id)) a,
  ];
  out.sort((a, b) {
    final l = b.level.index.compareTo(a.level.index);
    return l != 0 ? l : b.sent.compareTo(a.sent);
  });
  return out;
}

// ---------------------------------------------------------------- geometry

const _earthKm = 6371.0;

/// Great-circle distance in km.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = math.pi / 180;
  final dLat = (lat2 - lat1) * r, dLon = (lon2 - lon1) * r;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * r) * math.cos(lat2 * r) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthKm * math.asin(math.sqrt(h));
}

/// Compass direction from (lat1, lon1) to (lat2, lon2): 0 = N, 1 = NE … 7 = NW.
int compassOctant(double lat1, double lon1, double lat2, double lon2) {
  const r = math.pi / 180;
  final y = math.sin((lon2 - lon1) * r) * math.cos(lat2 * r);
  final x = math.cos(lat1 * r) * math.sin(lat2 * r) - math.sin(lat1 * r) * math.cos(lat2 * r) * math.cos((lon2 - lon1) * r);
  final deg = (math.atan2(y, x) / r + 360) % 360;
  return ((deg + 22.5) ~/ 45) % 8;
}

/// Ray casting. [polygon] is a list of (lat, lon).
bool pointInPolygon(double lat, double lon, List<(double, double)> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final (yi, xi) = polygon[i];
    final (yj, xj) = polygon[j];
    if ((yi > lat) != (yj > lat) && lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

/// Districts with at least one of their points inside a polygon or circle.
List<String> districtsInArea({
  List<List<(double, double)>> polygons = const [],
  List<(double, double, double)> circles = const [],
}) {
  final out = <String>[];
  for (final MapEntry(key: id, value: area) in bdDistrictAreas.entries) {
    final hit = area.points.any((p) =>
        polygons.any((poly) => poly.length >= 3 && pointInPolygon(p.$1, p.$2, poly)) ||
        circles.any((c) => distanceKm(p.$1, p.$2, c.$1, c.$2) <= c.$3));
    if (hit) out.add(id);
  }
  return out;
}

/// Districts with any point within [radiusKm] of (lat, lon), and the
/// nearest district with its distance.
({List<String> districts, String nearest, double nearestKm}) districtsNear(double lat, double lon, double radiusKm) {
  final out = <String>[];
  var nearest = '';
  var best = double.infinity;
  for (final MapEntry(key: id, value: area) in bdDistrictAreas.entries) {
    var d = double.infinity;
    for (final p in area.points) {
      d = math.min(d, distanceKm(lat, lon, p.$1, p.$2));
    }
    if (d <= radiusKm) out.add(id);
    if (d < best) {
      best = d;
      nearest = id;
    }
  }
  return (districts: out, nearest: nearest, nearestKm: best);
}
