import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/directory/data/content_cache.dart';

/// Downloads content published on the admin website.
///
/// One small document (meta/content) holds a version number the website
/// raises on every change. The app follows that document in real time, so
/// a phone that is online gets a change within seconds; only when the
/// version is newer than the phone's copy are the lists downloaded. It also
/// runs at start-up and whenever the phone comes back online.
class ContentSync {
  ContentSync(this._ref);

  final Ref _ref;
  bool _running = false;
  bool _runAgain = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _watch;
  static const _versionKey = 'content.version';

  /// The version of the content saved on this phone (0 = built-in data).
  int get localVersion => _ref.read(sharedPreferencesProvider).getInt(_versionKey) ?? 0;

  /// Follows meta/content and downloads each new version as it is published.
  Future<void> watch() async {
    if (_watch != null) return;
    if (!await _ref.read(firebaseReadyProvider.future)) return;
    _watch = FirebaseFirestore.instance.doc('meta/content').snapshots().listen(
      (snap) {
        final version = (snap.data()?['version'] as num?)?.toInt() ?? 0;
        if (version > localVersion) run();
      },
      onError: (Object e, StackTrace s) => AppLogger.error('Content watch stopped', e, s),
    );
  }

  Future<void> run() async {
    if (_running) {
      // A newer version may have been published while this download runs:
      // check again as soon as it finishes instead of missing it.
      _runAgain = true;
      return;
    }
    _running = true;
    try {
      do {
        _runAgain = false;
        await _download();
      } while (_runAgain);
    } finally {
      _running = false;
    }
  }

  Future<void> _download() async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return;
      final db = FirebaseFirestore.instance;
      const server = GetOptions(source: Source.server);

      final meta = await db.doc('meta/content').get(server).timeout(const Duration(seconds: 12));
      final version = (meta.data()?['version'] as num?)?.toInt() ?? 0;
      final prefs = _ref.read(sharedPreferencesProvider);
      if (version == 0 || version <= localVersion) return;

      // The website packs every published list into a few large documents
      // (snapshots/{collection}-{n}, listed in meta/content.chunks), so a
      // phone needs ~10 reads instead of one per hospital. Older websites
      // without chunks fall back to reading each collection.
      final chunks = meta.data()?['chunks'];
      // stamps: when each list last changed. A list whose stamp matches the
      // phone's copy is not downloaded again (an announcement must not make
      // every phone re-download 8,000 hospitals).
      final stamps = meta.data()?['stamps'];
      final old = await _ref.read(contentCacheProvider).read();
      final oldStamps = old?['stamps'] is Map ? old!['stamps'] as Map : const {};
      const cacheKey = {
        'emergency_numbers': 'numbers', 'guides': 'guides', 'hospitals': 'hospitals',
        'pharmacies': 'pharmacies', 'announcements': 'announcements', 'police_stations': 'policeStations',
      };
      Future<List<Map<String, dynamic>>> published(String collection) async {
        final count = chunks is Map ? (chunks[collection] as num?)?.toInt() : null;
        final stamp = stamps is Map ? stamps[collection] : null;
        final cached = old?[cacheKey[collection]];
        if (count != null && stamp != null && stamp == oldStamps[collection] && cached is List) {
          return [for (final x in cached) if (x is Map) Map<String, dynamic>.from(x)];
        }
        if (count != null) {
          final parts = await Future.wait([
            for (var i = 0; i < count; i++)
              db.doc('snapshots/$collection-$i').get(server).timeout(const Duration(seconds: 40)),
          ]);
          final out = <Map<String, dynamic>>[];
          for (final p in parts) {
            final json = p.data()?['json'];
            if (json is! String) throw StateError('snapshot $collection incomplete');
            for (final item in jsonDecode(json) as List) {
              if (item is Map) out.add(Map<String, dynamic>.from(item)..remove('published'));
            }
          }
          return out;
        }
        final snap = await db
            .collection(collection)
            .where('published', isEqualTo: true)
            .get(server)
            .timeout(const Duration(seconds: 30));
        return [
          for (final d in snap.docs)
            (_plain({...d.data(), 'id': d.id}) as Map<String, dynamic>)..remove('published'),
        ];
      }

      final lists = await Future.wait([
        published('emergency_numbers'),
        published('guides'),
        published('hospitals'),
        published('pharmacies'),
        published('announcements'),
        // Older websites have no police list yet: keep the phone's copy.
        if (chunks is Map && chunks['police_stations'] != null) published('police_stations') else Future.value(const <Map<String, dynamic>>[]),
      ]);
      final data = <String, dynamic>{
        'version': version,
        'updatedAt': _plain(meta.data()?['updatedAt']),
        'stamps': stamps is Map ? {for (final e in stamps.entries) '${e.key}': _plain(e.value)} : const {},
        'numbers': lists[0],
        'guides': lists[1],
        'hospitals': lists[2],
        'pharmacies': lists[3],
        'announcements': lists[4],
        'policeStations': lists[5].isNotEmpty ? lists[5] : (old?['policeStations'] ?? const []),
      };
      // Safety guard: never replace a working copy with one that has no
      // emergency numbers (a mistake on the website must not blank 999).
      if ((data['numbers'] as List).isEmpty) {
        data['numbers'] = old?['numbers'] ?? const [];
      }
      await _ref.read(contentCacheProvider).write(data);
      await prefs.setInt(_versionKey, version);
      _ref.invalidate(cachedContentProvider);
      AppLogger.info('Content updated to version $version');
    } catch (e, s) {
      AppLogger.error('Content sync failed (will retry later)', e, s);
    }
  }

  /// Firestore types (Timestamp) turned into plain JSON values.
  static Object? _plain(Object? v) {
    if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
    if (v is Map) return {for (final e in v.entries) e.key.toString(): _plain(e.value)};
    if (v is List) return [for (final x in v) _plain(x)];
    return v;
  }
}

final contentSyncProvider = Provider<ContentSync>((ref) => ContentSync(ref));
