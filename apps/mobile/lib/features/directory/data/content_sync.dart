import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/directory/data/content_cache.dart';

/// Downloads content published on the admin website.
///
/// Cheap check first: one small document (meta/content) holds a version
/// number the website raises on every change. Only when it is newer than the
/// phone's copy are the four lists downloaded. Runs at start-up and whenever
/// the phone comes back online.
class ContentSync {
  ContentSync(this._ref);

  final Ref _ref;
  bool _running = false;
  static const _versionKey = 'content.version';

  Future<void> run() async {
    if (_running) return;
    _running = true;
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return;
      final db = FirebaseFirestore.instance;
      const server = GetOptions(source: Source.server);

      final meta = await db.doc('meta/content').get(server).timeout(const Duration(seconds: 12));
      final version = (meta.data()?['version'] as num?)?.toInt() ?? 0;
      final prefs = _ref.read(sharedPreferencesProvider);
      if (version == 0 || version <= (prefs.getInt(_versionKey) ?? 0)) return;

      Future<List<Map<String, dynamic>>> published(String collection) async {
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

      final data = <String, dynamic>{
        'version': version,
        'numbers': await published('emergency_numbers'),
        'guides': await published('guides'),
        'hospitals': await published('hospitals'),
        'pharmacies': await published('pharmacies'),
      };
      // Safety guard: never replace a working copy with one that has no
      // emergency numbers (a mistake on the website must not blank 999).
      if ((data['numbers'] as List).isEmpty) {
        final old = await _ref.read(contentCacheProvider).read();
        data['numbers'] = old?['numbers'] ?? const [];
      }
      await _ref.read(contentCacheProvider).write(data);
      await prefs.setInt(_versionKey, version);
      _ref.invalidate(cachedContentProvider);
      AppLogger.info('Content updated to version $version');
    } catch (e, s) {
      AppLogger.error('Content sync failed (will retry later)', e, s);
    } finally {
      _running = false;
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
