import 'dart:convert';

import '../geo/bd_district_points.dart';
import '../geo/bd_locations.dart';
import '../localized_text.dart';
import 'hazard_alert.dart';

/// Earthquakes from the USGS catalogue (earthquake.usgs.gov) that could be
/// felt in Bangladesh.
///
/// No one can predict an earthquake. USGS publishes a quake minutes after it
/// happens; these alerts tell people what happened, where, and what to do
/// about aftershocks. Seconds-ahead warnings come only from the phone's own
/// Android Earthquake Alerts System.
abstract final class UsgsQuakes {
  /// Bangladesh and the seismic belts around it (Himalaya, Shillong plateau,
  /// Indo-Burma ranges, Andaman arc).
  static Uri query(DateTime since, {double minMagnitude = 4.0}) => Uri.https('earthquake.usgs.gov', '/fdsnws/event/1/query', {
        'format': 'geojson',
        'starttime': since.toUtc().toIso8601String().substring(0, 19),
        'minlatitude': '15',
        'maxlatitude': '31',
        'minlongitude': '82',
        'maxlongitude': '100',
        'minmagnitude': '$minMagnitude',
        'orderby': 'time',
      });

  /// How far from the epicentre a quake of this size is usually felt
  /// (rough, for shallow quakes).
  static double feltRadiusKm(double magnitude) => switch (magnitude) {
        < 4.5 => 120,
        < 5.0 => 200,
        < 5.5 => 300,
        < 6.0 => 400,
        < 6.5 => 550,
        < 7.0 => 700,
        _ => 1000,
      };

  /// How serious it is for the nearest part of Bangladesh.
  static AlertLevel levelFor(double magnitude, double distanceKm) {
    if (magnitude >= 6.0 && distanceKm <= 300 || magnitude >= 7.0 && distanceKm <= 600) return AlertLevel.emergency;
    if (magnitude >= 5.0 && distanceKm <= 250 || magnitude >= 6.0 && distanceKm <= 600) return AlertLevel.warning;
    if (magnitude >= 4.5 && distanceKm <= 150 || magnitude >= 5.0 && distanceKm <= 400) return AlertLevel.watch;
    return AlertLevel.advisory;
  }

  /// How long a quake stays on the alert list.
  static const life = Duration(hours: 48);

  /// Parses a USGS GeoJSON response. Quakes too far away to be felt in
  /// Bangladesh are left out.
  static List<HazardAlert> parse(String geojson) {
    final Object? json;
    try {
      json = jsonDecode(geojson);
    } catch (_) {
      return const [];
    }
    if (json is! Map || json['features'] is! List) return const [];
    final out = <HazardAlert>[];
    for (final f in json['features'] as List) {
      try {
        final a = fromFeature(Map<String, dynamic>.from(f as Map));
        if (a != null) out.add(a);
      } catch (_) {
        // One odd entry must never hide the rest.
      }
    }
    return out;
  }

  static HazardAlert? fromFeature(Map<String, dynamic> f) {
    final p = Map<String, dynamic>.from(f['properties'] as Map);
    final coords = (f['geometry'] as Map)['coordinates'] as List;
    final lon = (coords[0] as num).toDouble(), lat = (coords[1] as num).toDouble();
    final depth = coords.length > 2 ? (coords[2] as num?)?.toDouble() : null;
    final mag = (p['mag'] as num?)?.toDouble();
    final time = (p['time'] as num?)?.toInt();
    if (mag == null || time == null) return null;
    if ((p['type'] as String?) != null && p['type'] != 'earthquake') return null;

    final near = districtsNear(lat, lon, feltRadiusKm(mag));
    if (near.districts.isEmpty) return null;
    final sent = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);
    final district = BdLocations.district(near.nearest);
    final km = near.nearestKm;
    final inside = km < 8;
    final centre = bdDistrictAreas[near.nearest];
    final dir = centre == null ? 0 : compassOctant(centre.lat, centre.lon, lat, lon);
    final magText = mag.toStringAsFixed(1);
    final kmText = (km / 5).round() * 5;
    final whereEn = inside ? 'in ${district?.en} district' : '$kmText km ${_dirEn[dir]} of ${district?.en}';
    final whereBn = inside ? '${district?.bn} জেলায়' : '${district?.bn} থেকে $kmText কিমি ${_dirBn[dir]}ে';
    final level = levelFor(mag, km);

    return HazardAlert(
      id: '${AlertSource.usgs}-${f['id']}',
      source: AlertSource.usgs,
      hazard: Hazard.earthquake,
      level: level,
      headline: LocalizedText(
        en: 'Earthquake of magnitude $magText, $whereEn',
        bn: '$magText মাত্রার ভূমিকম্প, $whereBn',
      ),
      description: LocalizedText(
        en: 'A magnitude $magText earthquake struck ${p['place'] ?? ''}'
            '${depth != null ? ' at a depth of ${depth.round()} km' : ''}. '
            'It may have been felt in ${near.districts.length} districts of Bangladesh. '
            'Aftershocks can follow for hours or days.',
        bn: '$magText মাত্রার একটি ভূমিকম্প হয়েছে (${p['place'] ?? ''})'
            '${depth != null ? ', ভূপৃষ্ঠ থেকে ${depth.round()} কিমি গভীরে' : ''}। '
            'বাংলাদেশের ${near.districts.length}টি জেলায় এটি অনুভূত হয়ে থাকতে পারে। '
            'পরের কয়েক ঘণ্টা বা দিনে আফটারশক (পরাঘাত) হতে পারে।',
      ),
      instruction: level.notifies
          ? const LocalizedText(
              en: 'If you are inside a damaged building, go out carefully once the shaking stops. '
                  'Stay away from cracked walls, electric wires and gas lines. Expect aftershocks: Drop, Cover, Hold on.',
              bn: 'ক্ষতিগ্রস্ত ভবনে থাকলে কাঁপুনি থামার পর সাবধানে বাইরে বের হোন। ফাটল ধরা দেয়াল, বিদ্যুতের তার ও গ্যাস লাইন থেকে দূরে থাকুন। '
                  'আফটারশকের জন্য প্রস্তুত থাকুন: বসে পড়ুন, মাথা ঢাকুন, ধরে থাকুন।',
            )
          : const LocalizedText(en: '', bn: ''),
      areaText: LocalizedText(en: p['place'] as String? ?? '', bn: ''),
      districts: near.districts..sort(),
      sent: sent,
      expires: sent.add(life),
      web: (p['url'] as String?) ?? '',
      quake: QuakeInfo(
        magnitude: mag,
        lat: lat,
        lon: lon,
        depthKm: depth,
        place: (p['place'] as String?) ?? '',
        nearestDistrictId: near.nearest,
        distanceKm: km,
      ),
    );
  }

  static const _dirEn = ['north', 'north-east', 'east', 'south-east', 'south', 'south-west', 'west', 'north-west'];
  static const _dirBn = ['উত্তর', 'উত্তর-পূর্ব', 'পূর্ব', 'দক্ষিণ-পূর্ব', 'দক্ষিণ', 'দক্ষিণ-পশ্চিম', 'পশ্চিম', 'উত্তর-পশ্চিম'];
}
