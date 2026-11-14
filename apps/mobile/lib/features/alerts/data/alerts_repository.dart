import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';

/// Where alerts come from:
///
/// 1. Firestore meta/alerts, followed live. "official" is written every 10
///    minutes by the alert watcher (BMD warnings and USGS earthquakes,
///    tools/alerts); "team" by the admin website.
/// 2. If that list is older than [staleAfter] (watcher down) or Firebase is
///    not available, the phone reads BMD and USGS itself.
/// 3. The last list is kept on the phone, so alerts still show offline.
class AlertFeed {
  const AlertFeed({this.official = const [], this.team = const [], this.checkedAt, this.direct = false});

  final List<HazardAlert> official;
  final List<HazardAlert> team;

  /// When the official sources were last checked.
  final DateTime? checkedAt;

  /// True when the phone read BMD and USGS itself.
  final bool direct;

  static const staleAfter = Duration(minutes: 45);

  List<HazardAlert> active(DateTime now) => activeAlerts([...team, ...official], now);

  Map<String, dynamic> toJson() => {
        'official': [for (final a in official) a.toJson()],
        'team': [for (final a in team) a.toJson()],
        if (checkedAt != null) 'checkedAt': checkedAt!.toIso8601String(),
        'direct': direct,
      };

  factory AlertFeed.fromJson(Map<String, dynamic> j) => AlertFeed(
        official: parseAlertList(j['official']),
        team: parseAlertList(j['team']),
        checkedAt: DateTime.tryParse('${j['checkedAt'] ?? ''}'),
        direct: j['direct'] == true,
      );
}

/// A JSON list (or a JSON string of one) of alerts; broken entries are skipped.
List<HazardAlert> parseAlertList(Object? raw) {
  Object? list = raw;
  if (raw is String) {
    if (raw.trim().isEmpty) return const [];
    try {
      list = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
  }
  if (list is! List) return const [];
  final out = <HazardAlert>[];
  for (final item in list) {
    try {
      if (item is Map) out.add(HazardAlert.fromJson(Map<String, dynamic>.from(item)));
    } catch (_) {
      // One broken alert must never hide the others.
    }
  }
  return out;
}

const _cacheKey = 'alerts.feed';

/// The live alert list. Starts with the copy saved on the phone.
final alertFeedProvider = StreamProvider<AlertFeed>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final controller = StreamController<AlertFeed>();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
  var last = const AlertFeed();
  var directRunning = false;

  void emit(AlertFeed feed) {
    last = feed;
    if (!controller.isClosed) controller.add(feed);
    prefs.setString(_cacheKey, jsonEncode(feed.toJson())).ignore();
  }

  Future<void> readDirect() async {
    if (directRunning) return;
    directRunning = true;
    try {
      final official = await fetchOfficialAlerts();
      if (official != null) emit(AlertFeed(official: official, team: last.team, checkedAt: DateTime.now().toUtc(), direct: true));
    } finally {
      directRunning = false;
    }
  }

  try {
    final saved = prefs.getString(_cacheKey);
    if (saved != null) last = AlertFeed.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  } catch (_) {}
  controller.add(last);

  () async {
    if (!await ref.read(firebaseReadyProvider.future)) {
      await readDirect();
      return;
    }
    sub = FirebaseFirestore.instance.doc('meta/alerts').snapshots().listen(
      (snap) {
        final d = snap.data() ?? const {};
        final checked = DateTime.tryParse('${d['officialAt'] ?? ''}');
        final feed = AlertFeed(official: parseAlertList(d['official']), team: parseAlertList(d['team']), checkedAt: checked);
        // Watcher not running? Read the sources directly, keep the team list.
        final stale = checked == null || DateTime.now().toUtc().difference(checked) > AlertFeed.staleAfter;
        if (stale && last.direct && last.checkedAt != null &&
            DateTime.now().toUtc().difference(last.checkedAt!) < AlertFeed.staleAfter) {
          emit(AlertFeed(official: last.official, team: feed.team, checkedAt: last.checkedAt, direct: true));
        } else {
          emit(feed);
        }
        if (stale) readDirect();
      },
      onError: (Object e, StackTrace s) {
        AppLogger.error('Alert watch stopped', e, s);
        readDirect();
      },
    );
  }();

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Alerts the phone read itself when the person pulled to refresh.
final refreshedAlertsProvider = StateProvider<List<HazardAlert>>((ref) => const []);

/// Active alerts, most serious first.
final activeAlertsProvider = Provider<List<HazardAlert>>((ref) {
  final feed = ref.watch(alertFeedProvider).valueOrNull ?? const AlertFeed();
  final refreshed = ref.watch(refreshedAlertsProvider);
  return activeAlerts([...feed.team, ...feed.official, ...refreshed], DateTime.now().toUtc());
});

/// Reads BMD's CAP feed and the USGS earthquake list directly. Null when
/// neither could be reached.
Future<List<HazardAlert>?> fetchOfficialAlerts() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  client.userAgent = 'JoruriBD-app';
  Future<String> get(Uri url) async {
    final req = await client.getUrl(url);
    final res = await req.close().timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: url);
    return res.transform(utf8.decoder).join();
  }

  final now = DateTime.now().toUtc();
  var reached = false;
  final out = <HazardAlert>[];
  try {
    final feed = parseCapFeed(await get(Uri.parse('https://cap.bmd.gov.bd/api/cap/rss.xml')));
    reached = true;
    final replaced = <String>{};
    final bulletins = <HazardAlert>[];
    for (final item in feed) {
      if (item.published != null && now.difference(item.published!) > const Duration(days: 10)) continue;
      try {
        final xml = await get(Uri.parse(item.url));
        replaced.addAll(capReferences(xml).map((id) => '${AlertSource.bmd}-$id'));
        final a = parseCapAlert(xml);
        if (a != null) bulletins.add(a);
      } catch (_) {}
    }
    out.addAll(bulletins.where((a) => !replaced.contains(a.id)));
  } catch (e) {
    AppLogger.info('BMD not reachable: $e');
  }
  try {
    out.addAll(UsgsQuakes.parse(await get(UsgsQuakes.query(now.subtract(UsgsQuakes.life)))));
    reached = true;
  } catch (e) {
    AppLogger.info('USGS not reachable: $e');
  } finally {
    client.close();
  }
  return reached ? activeAlerts(out, now) : null;
}

// ------------------------------------------------------------------ settings

/// What this phone is told about.
class AlertSettings {
  const AlertSettings({this.notify = true, this.districtId, this.everywhere = false});

  /// Phone notifications for serious alerts.
  final bool notify;

  /// The district to be warned for; null = the district in the profile.
  final String? districtId;

  /// Notifications for the whole of Bangladesh, not just one district.
  final bool everywhere;

  AlertSettings copyWith({bool? notify, String? Function()? districtId, bool? everywhere}) => AlertSettings(
        notify: notify ?? this.notify,
        districtId: districtId == null ? this.districtId : districtId(),
        everywhere: everywhere ?? this.everywhere,
      );
}

final alertSettingsProvider = NotifierProvider<AlertSettingsController, AlertSettings>(AlertSettingsController.new);

class AlertSettingsController extends Notifier<AlertSettings> {
  static const _notify = 'alerts.notify';
  static const _district = 'alerts.districtId';
  static const _everywhere = 'alerts.everywhere';

  @override
  AlertSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AlertSettings(
      notify: p.getBool(_notify) ?? true,
      districtId: p.getString(_district),
      everywhere: p.getBool(_everywhere) ?? false,
    );
  }

  void setNotify(bool v) {
    state = state.copyWith(notify: v);
    ref.read(sharedPreferencesProvider).setBool(_notify, v);
  }

  void setDistrict(String? id) {
    state = state.copyWith(districtId: () => id);
    final p = ref.read(sharedPreferencesProvider);
    id == null ? p.remove(_district) : p.setString(_district, id);
  }

  void setEverywhere(bool v) {
    state = state.copyWith(everywhere: v);
    ref.read(sharedPreferencesProvider).setBool(_everywhere, v);
  }
}

/// The district this phone is warned for: chosen for alerts, else the profile's.
final alertDistrictProvider = Provider<String?>((ref) {
  final chosen = ref.watch(alertSettingsProvider.select((s) => s.districtId));
  if (chosen != null && BdLocations.district(chosen) != null) return chosen;
  final home = ref.watch(profileProvider.select((p) => p?.districtId));
  return home != null && BdLocations.district(home) != null ? home : null;
});
