// Disaster alert watcher. Runs every 10 minutes on GitHub Actions
// (.github/workflows/alerts.yml), or by hand:
//
//   cd tools/alerts && dart run bin/watch.dart --dry-run
//
// 1. Reads the official warnings: Bangladesh Meteorological Department's CAP
//    feed (cyclones, heavy rain, heat and cold waves, storms, fog) and the
//    USGS list of earthquakes that can be felt in Bangladesh.
// 2. Publishes the active ones to Firestore meta/alerts ("official"), which
//    every open app follows live. The team's own alerts ("team") are written
//    there by the admin website.
// 3. Sends each new serious alert (official or team) as a push notification
//    to the FCM topics of the districts it covers, in Bangla and English:
//    alerts-bn-<district>, alerts-en-<district>, and alerts-<lang>-all for
//    phones that follow the whole country. meta/alertsPushed remembers what
//    was sent, so nothing is sent twice.
//
// Sign-in: GOOGLE_ACCESS_TOKEN (GitHub Actions, workload identity) or the
// Firebase CLI login on this computer (`firebase login` as a project owner).
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:joruri_core/joruri_core.dart';

const project = 'joruri-bd';
const docs = 'https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents';
const userAgent = 'JoruriBD-alerts/1.0 (+https://github.com/Ashfaq1306/joruri-bd)';

/// Only alerts this fresh are pushed; older ones are shown in the app only.
const pushWindow = Duration(hours: 12);
const quakePushWindow = Duration(hours: 3);

late final bool dryRun;
late final bool noPush;
String? _token;

Future<void> main(List<String> args) async {
  dryRun = args.contains('--dry-run');
  noPush = args.contains('--no-push') || dryRun;
  final now = DateTime.now().toUtc();
  _token = Platform.environment['GOOGLE_ACCESS_TOKEN'] ?? await cliToken();

  final official = <HazardAlert>[...await bmdAlerts(now), ...await usgsAlerts(now)];
  final active = activeAlerts(official, now);
  log('active official alerts: ${active.length}');
  for (final a in active) {
    log('  ${a.level.name.padRight(9)} ${a.hazard.name.padRight(10)} ${a.headline.en}  [${a.nationwide ? 'all' : a.districts.length}]');
  }

  // Publish to meta/alerts only when something changed: every write is one
  // read for each phone following the document.
  final meta = await getDoc('meta/alerts');
  final officialJson = jsonEncode([for (final a in active) a.toJson()]);
  if (meta?['official'] != officialJson) {
    await patchDoc('meta/alerts', {'official': officialJson, 'officialAt': now.toIso8601String()});
    log('meta/alerts updated');
  }

  final team = <HazardAlert>[];
  final teamJson = meta?['team'];
  if (teamJson is String && teamJson.isNotEmpty) {
    for (final j in jsonDecode(teamJson) as List) {
      try {
        team.add(HazardAlert.fromJson(Map<String, dynamic>.from(j as Map)));
      } catch (e) {
        log('unreadable team alert: $e');
      }
    }
  }

  // Push the new ones.
  final pushedDoc = await getDoc('meta/alertsPushed');
  final pushed = <String, String>{
    if (pushedDoc?['ids'] is String) ...Map<String, String>.from(jsonDecode(pushedDoc!['ids'] as String) as Map),
  };
  var changed = false;
  for (final a in activeAlerts([...active, ...team], now)) {
    if (pushed.containsKey(a.id) || !a.push || !a.level.notifies) continue;
    final age = now.difference(a.sent);
    if (age > (a.hazard == Hazard.earthquake ? quakePushWindow : pushWindow)) continue;
    if (!a.nationwide && a.districts.isEmpty) continue;
    final sent = await pushAlert(a, now);
    if (sent > 0 || noPush) {
      log('pushed ${a.id} to $sent topics');
      if (!noPush) {
        pushed[a.id] = now.toIso8601String();
        changed = true;
      }
    }
  }
  // Forget pushes older than 30 days.
  final before = pushed.length;
  pushed.removeWhere((_, at) => now.difference(DateTime.parse(at)) > const Duration(days: 30));
  if (changed || pushed.length != before) {
    await patchDoc('meta/alertsPushed', {'ids': jsonEncode(pushed), 'at': now.toIso8601String()});
  }
  log('done');
}

// ------------------------------------------------------------------ sources

Future<List<HazardAlert>> bmdAlerts(DateTime now) async {
  try {
    final feed = parseCapFeed(await getText(Uri.parse('https://cap.bmd.gov.bd/api/cap/rss.xml')));
    final out = <HazardAlert>[];
    final replaced = <String>{};
    for (final item in feed) {
      // Bulletins older than 10 days have expired long ago.
      if (item.published != null && now.difference(item.published!) > const Duration(days: 10)) continue;
      try {
        final xml = await getText(Uri.parse(item.url));
        replaced.addAll(capReferences(xml).map((id) => '${AlertSource.bmd}-$id'));
        final a = parseCapAlert(xml);
        if (a != null) out.add(a);
      } catch (e) {
        log('BMD ${item.url}: $e');
      }
    }
    return out.where((a) => !replaced.contains(a.id)).toList();
  } catch (e) {
    // BMD unreachable: keep going with the other sources. The app keeps
    // showing the last list until each alert's own end time.
    log('BMD feed unreachable: $e');
    return const [];
  }
}

Future<List<HazardAlert>> usgsAlerts(DateTime now) async {
  try {
    return UsgsQuakes.parse(await getText(UsgsQuakes.query(now.subtract(UsgsQuakes.life))));
  } catch (e) {
    log('USGS unreachable: $e');
    return const [];
  }
}

// ---------------------------------------------------------------------- push

/// Sends [a] to every topic it concerns, in both languages. Returns the
/// number of messages accepted.
Future<int> pushAlert(HazardAlert a, DateTime now) async {
  final districts = a.nationwide ? bdDistrictAreas.keys.toList() : a.districts;
  final topics = [
    for (final lang in ['bn', 'en']) ...[
      'alerts-$lang-all',
      for (final d in districts) 'alerts-$lang-$d',
    ],
  ];
  if (noPush) {
    log('would push "${a.headline.en}" to ${topics.length} topics');
    return 0;
  }
  final ttl = a.endsAt.difference(now).inSeconds.clamp(600, 3 * 24 * 3600);
  final channel = a.level == AlertLevel.emergency || a.level == AlertLevel.warning ? 'alerts_urgent' : 'alerts';
  var ok = 0;
  for (final topic in topics) {
    final bn = topic.startsWith('alerts-bn-');
    final title = '${_levelWord(a.level, bn)}: ${a.headline.resolve(bn ? 'bn' : 'en')}';
    final body = _short((a.instruction.isEmpty ? a.description : a.instruction).resolve(bn ? 'bn' : 'en'), 400);
    final message = {
      'message': {
        'topic': topic,
        'notification': {'title': _short(title, 120), 'body': body},
        'data': {'alertId': a.id, 'route': '/alerts/${Uri.encodeComponent(a.id)}'},
        'android': {
          'priority': 'HIGH',
          'ttl': '${ttl}s',
          'notification': {
            'channel_id': channel,
            'tag': a.id,
            'icon': 'ic_stat_alert',
            'color': a.level.index >= AlertLevel.warning.index ? '#D32F2F' : '#E37400',
            'default_sound': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
      },
    };
    final r = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/$project/messages:send'),
      headers: {'authorization': 'Bearer $_token', 'content-type': 'application/json'},
      body: jsonEncode(message),
    );
    if (r.statusCode == 200) {
      ok++;
    } else {
      log('FCM $topic: ${r.statusCode} ${r.body.length > 300 ? r.body.substring(0, 300) : r.body}');
      if (r.statusCode == 401 || r.statusCode == 403) break;
    }
  }
  return ok;
}

String _levelWord(AlertLevel l, bool bn) => switch (l) {
      AlertLevel.emergency => bn ? 'জরুরি বিপদ' : 'EMERGENCY',
      AlertLevel.warning => bn ? 'সতর্কবার্তা' : 'Warning',
      AlertLevel.watch => bn ? 'সতর্ক থাকুন' : 'Be alert',
      AlertLevel.advisory => bn ? 'তথ্য' : 'Advisory',
    };

String _short(String s, int n) => s.length <= n ? s : '${s.substring(0, n - 1)}…';

// ------------------------------------------------------------------- helpers

void log(String s) => stdout.writeln(s);

Future<String> getText(Uri url) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final r = await http.get(url, headers: {'user-agent': userAgent}).timeout(const Duration(seconds: 40));
      if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
      throw HttpException('HTTP ${r.statusCode}', uri: url);
    } catch (e) {
      if (attempt >= 3) rethrow;
      await Future<void>.delayed(Duration(seconds: 3 * attempt));
    }
  }
}

Future<Map<String, dynamic>?> getDoc(String path) async {
  final r = await http.get(Uri.parse('$docs/$path'), headers: {'authorization': 'Bearer $_token'});
  if (r.statusCode == 404) return null;
  if (r.statusCode != 200) throw HttpException('Firestore read $path: ${r.statusCode} ${r.body}');
  final fields = (jsonDecode(r.body) as Map)['fields'] as Map? ?? const {};
  return {for (final e in fields.entries) e.key as String: (e.value as Map)['stringValue'] ?? (e.value as Map).values.first};
}

/// Writes only [fields] (strings); the other fields of the document stay.
Future<void> patchDoc(String path, Map<String, String> fields) async {
  if (dryRun) {
    log('(dry run) would write $path: ${fields.keys.join(', ')}');
    return;
  }
  final mask = fields.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
  final r = await http.patch(
    Uri.parse('$docs/$path?$mask'),
    headers: {'authorization': 'Bearer $_token', 'content-type': 'application/json'},
    body: jsonEncode({
      'fields': {for (final e in fields.entries) e.key: {'stringValue': e.value}},
    }),
  );
  if (r.statusCode != 200) throw HttpException('Firestore write $path: ${r.statusCode} ${r.body}');
}

/// Access token from the Firebase CLI login on this computer.
Future<String> cliToken() async {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  final file = File('$home/.config/configstore/firebase-tools.json');
  if (!file.existsSync()) throw StateError('Set GOOGLE_ACCESS_TOKEN or run `firebase login`.');
  final refresh = ((jsonDecode(file.readAsStringSync()) as Map)['tokens'] as Map)['refresh_token'];
  // The Firebase CLI's public OAuth client, as in tools/lib/firestore.mjs.
  final r = await http.post(Uri.parse('https://oauth2.googleapis.com/token'), body: {
    'grant_type': 'refresh_token',
    'refresh_token': refresh,
    'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
  });
  final token = (jsonDecode(r.body) as Map)['access_token'];
  if (token is! String) throw StateError('Firebase CLI login expired: run `firebase login`.');
  return token;
}
