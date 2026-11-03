import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

/// The last content downloaded from the admin website, saved on the phone.
/// Used instead of the bundled seed data once it exists, so updates survive
/// restarts and work offline.
class ContentCache {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/content_cache.json');

  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      // Several MB with every hospital: decoded off the UI thread.
      return await compute(_decodeMap, await file.readAsString());
    } catch (e, s) {
      AppLogger.error('Content cache unreadable; using bundled data', e, s);
      return null;
    }
  }

  /// Written to a temporary file first, so a crash mid-write never leaves
  /// a broken cache behind.
  Future<void> write(Map<String, dynamic> data) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(await compute(jsonEncode, data), flush: true);
    await temp.rename(file.path);
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

Map<String, dynamic> _decodeMap(String text) => jsonDecode(text) as Map<String, dynamic>;

final contentCacheProvider = Provider<ContentCache>((ref) => ContentCache());

/// null = nothing downloaded yet (bundled data is used).
final cachedContentProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) => ref.watch(contentCacheProvider).read(),
);

/// Parses one section of the cache. null when the section is missing or
/// empty, so the caller falls back to the bundled data for that section.
List<T>? parseSection<T>(Map<String, dynamic>? cache, String key, T Function(Map<String, dynamic>) parse) {
  final raw = cache?[key];
  if (raw is! List || raw.isEmpty) return null;
  final out = <T>[];
  for (final item in raw) {
    try {
      out.add(parse(Map<String, dynamic>.from(item as Map)));
    } catch (_) {
      // Skip one broken entry, keep the rest.
    }
  }
  return out.isEmpty ? null : out;
}
