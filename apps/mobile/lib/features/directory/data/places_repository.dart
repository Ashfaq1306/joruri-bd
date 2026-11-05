import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/directory/data/content_cache.dart';

/// Hospitals (with tests and prices) and pharmacies your team provides,
/// bundled in the app so they work offline. Filled by tool/import_places.dart.
class PlacesRepository {
  PlacesRepository(this._bundle);

  final AssetBundle _bundle;

  Future<List<Hospital>> hospitals([Hospital Function(Map<String, dynamic>) parse = Hospital.fromJson]) async => [
        ...await _load('assets/seed/hospitals.json', 'hospitals', parse),
        if (AppConfig.showDemoPlaces) ...await _load('assets/seed/hospitals_demo.json', 'hospitals', parse),
      ];

  Future<List<Pharmacy>> pharmacies() async => [
        ...await _load('assets/seed/pharmacies.json', 'pharmacies', Pharmacy.fromJson),
        if (AppConfig.showDemoPlaces)
          ...await _load('assets/seed/pharmacies_demo.json', 'pharmacies', Pharmacy.fromJson),
      ];

  /// Licensed pharmacies of one district from the DGDA register, bundled as
  /// `assets/seed/pharmacies/{districtId}.json`, so only one district is read.
  Future<List<Pharmacy>> registerPharmacies(String districtId) async {
    if (!_districtIds.contains(districtId)) return const [];
    return _load('assets/seed/pharmacies/$districtId.json', 'pharmacies',
        (json) => Pharmacy.fromJson({...json, 'districtId': districtId, 'source': 'DGDA'}));
  }

  static final _districtIds = {for (final d in BdLocations.districts) d.id};

  /// Every police station (thana) with its OC's number, bundled so the list
  /// works offline (assets/seed/police_stations.json, tools/police-import).
  Future<List<Station>> policeStations() => _load('assets/seed/police_stations.json', 'policeStations', Station.fromJson);

  /// Every fire station and Fire Service office with its number, from the
  /// Fire Service and Civil Defence's own lists (tools/fire-import).
  Future<List<Station>> fireStations() => _load('assets/seed/fire_stations.json', 'fireStations', Station.fromJson);

  /// DGDA-registered medicines with approved prices (assets/seed/medicines.json).
  Future<MedicineList> medicines() async {
    try {
      return await compute(_decodeMedicines, await _bundle.loadString('assets/seed/medicines.json'));
    } catch (e, s) {
      AppLogger.error('Could not read medicines.json', e, s);
      return const MedicineList([], '');
    }
  }

  Future<List<T>> _load<T>(String path, String key, T Function(Map<String, dynamic>) parse) async {
    try {
      final json = await compute(_decodeMap, await _bundle.loadString(path));
      final out = <T>[];
      for (final item in (json[key] as List? ?? const [])) {
        try {
          out.add(parse(item as Map<String, dynamic>));
        } catch (_) {
          // One broken row must never hide the rest.
        }
      }
      return out;
    } catch (e, s) {
      AppLogger.error('Could not read $path', e, s);
      return const [];
    }
  }
}

Map<String, dynamic> _decodeMap(String text) => jsonDecode(text) as Map<String, dynamic>;

/// The medicine list and the date DGDA's prices were downloaded.
class MedicineList {
  const MedicineList(this.items, this.downloadedOn);
  final List<Medicine> items;
  final String downloadedOn;
}

MedicineList _decodeMedicines(String text) {
  final json = jsonDecode(text) as Map<String, dynamic>;
  final companies = [for (final c in (json['companies'] as List? ?? const [])) c.toString()];
  final out = <Medicine>[];
  for (final row in (json['medicines'] as List? ?? const [])) {
    try {
      out.add(Medicine.fromRow(row as List, companies));
    } catch (_) {
      // One broken row must never hide the rest.
    }
  }
  return MedicineList(out, (json['downloadedOn'] as String?) ?? '');
}

final placesRepositoryProvider = Provider<PlacesRepository>((ref) => PlacesRepository(rootBundle));
/// Hospitals published on the admin website when downloaded; otherwise the
/// bundled list (plus demo data while that is switched on).
final hospitalsProvider = FutureProvider<List<Hospital>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  final charts = await ref.watch(feeChartsProvider.future);
  Hospital parse(Map<String, dynamic> json) => Hospital.fromJson(withFeeChart(json, charts));
  return parseSection(cache, 'hospitals', parse) ?? await ref.watch(placesRepositoryProvider).hospitals(parse);
});

/// Shared price lists (e.g. the government user-fee chart), so 700 hospitals
/// do not each carry the same prices. A hospital with "feeChart" and no tests
/// of its own gets the chart's tests.
final feeChartsProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  try {
    final json = jsonDecode(await rootBundle.loadString('assets/seed/fee_charts.json')) as Map<String, dynamic>;
    return {for (final e in json.entries) if (e.value is List) e.key: e.value as List};
  } catch (e, s) {
    AppLogger.error('Fee charts unreadable', e, s);
    return const {};
  }
});

Map<String, dynamic> withFeeChart(Map<String, dynamic> json, Map<String, List<dynamic>> charts) {
  final chart = charts[json['feeChart']];
  final own = json['tests'];
  if (chart == null || (own is List && own.isNotEmpty)) return json;
  return {...json, 'tests': chart};
}

/// Pharmacies added or checked by the team on the admin website (24-hour
/// shops, verified numbers). Few; downloaded with the other content.
final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  return parseSection(cache, 'pharmacies', Pharmacy.fromJson) ?? await ref.watch(placesRepositoryProvider).pharmacies();
});

/// Every pharmacy of one district: the team's entries first, then the DGDA
/// register (a register entry is left out when the team has the same licence).
final districtPharmaciesProvider = FutureProvider.family<List<Pharmacy>, String>((ref, districtId) async {
  final team = (await ref.watch(pharmaciesProvider.future)).where((p) => p.districtId == districtId).toList();
  final register = await ref.watch(placesRepositoryProvider).registerPharmacies(districtId);
  final known = {for (final p in team) if (p.licence.isNotEmpty) p.licence.toLowerCase()};
  return [...team, ...register.where((p) => !known.contains(p.licence.toLowerCase()))];
});

/// Police stations published on the admin website when downloaded;
/// otherwise the bundled list.
final policeStationsProvider = FutureProvider<List<Station>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  return parseSection(cache, 'policeStations', Station.fromJson) ?? await ref.watch(placesRepositoryProvider).policeStations();
});

/// Fire stations published on the admin website when downloaded;
/// otherwise the bundled list.
final fireStationsProvider = FutureProvider<List<Station>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  Station parse(Map<String, dynamic> json) => Station.fromJson({...json, 'service': 'fire'});
  return parseSection(cache, 'fireStations', parse) ?? await ref.watch(placesRepositoryProvider).fireStations();
});

/// The police or fire station list.
FutureProvider<List<Station>> stationsProvider(StationService service) =>
    service == StationService.fire ? fireStationsProvider : policeStationsProvider;

/// Loaded once, the first time the medicine search opens.
final medicinesProvider = FutureProvider<MedicineList>((ref) => ref.watch(placesRepositoryProvider).medicines());

/// The area chosen on the Hospitals and Pharmacy screens, remembered on this phone.
final placeFilterProvider = NotifierProvider<PlaceFilterController, PlaceFilter>(PlaceFilterController.new);

class PlaceFilterController extends Notifier<PlaceFilter> {
  static const _divisionKey = 'place.divisionId';
  static const _districtKey = 'place.districtId';

  @override
  PlaceFilter build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PlaceFilter(divisionId: prefs.getString(_divisionKey), districtId: prefs.getString(_districtKey));
  }

  void setDivision(String? id) {
    state = state.copyWith(divisionId: () => id, districtId: () => null);
    _remember();
  }

  void setDistrict(String? id) {
    final division = id == null ? state.divisionId : BdLocations.district(id)?.divisionId;
    state = state.copyWith(districtId: () => id, divisionId: () => division);
    _remember();
  }

  void setArea(String text) => state = state.copyWith(areaText: text);

  void _remember() {
    final prefs = ref.read(sharedPreferencesProvider);
    final division = state.divisionId;
    final district = state.districtId;
    division == null ? prefs.remove(_divisionKey) : prefs.setString(_divisionKey, division);
    district == null ? prefs.remove(_districtKey) : prefs.setString(_districtKey, district);
  }
}
