import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/remote/app_meta.dart';
import 'package:joruri_bd/features/directory/data/content_cache.dart';

/// Emergency content bundled inside the app, so it works on a phone that
/// has never been online.
///
/// Phase 5 swaps this for a synced local database without changing any
/// screen: screens only see these providers.
class ContentRepository {
  ContentRepository(this._bundle);

  final AssetBundle _bundle;
  List<EmergencyNumber>? _numbers;
  List<Guide>? _guides;

  Future<List<EmergencyNumber>> numbers() async {
    return _numbers ??= ((jsonDecode(await _bundle.loadString('assets/seed/emergency_numbers.json'))
                as Map<String, dynamic>)['numbers'] as List)
        .whereType<Map<String, dynamic>>()
        .map(EmergencyNumber.fromJson)
        .toList(growable: false);
  }

  Future<List<Guide>> guides() async {
    return _guides ??= ((jsonDecode(await _bundle.loadString('assets/seed/guides.json'))
                as Map<String, dynamic>)['guides'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Guide.fromJson)
        .toList(growable: false);
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) => ContentRepository(rootBundle));

/// National number first, then by category. Unverified entries only appear
/// while the admins allow it (App & updates page), and always carry a label.
final emergencyNumbersProvider = FutureProvider<List<EmergencyNumber>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  final all = parseSection(cache, 'numbers', EmergencyNumber.fromJson) ??
      await ref.watch(contentRepositoryProvider).numbers();
  final showUnverified = ref.watch(showUnverifiedContentProvider);
  return sortEmergencyNumbers([
    for (final n in all)
      if (n.verification.isVerified || showUnverified) n,
  ]);
});

/// 999 first, then by category (police, fire, ambulance, health …), short
/// codes before full numbers; otherwise the published order is kept.
/// (It was not sorted before, so 102 could appear above 999.)
List<EmergencyNumber> sortEmergencyNumbers(List<EmergencyNumber> list) {
  final indexed = list.indexed.toList();
  indexed.sort((a, b) {
    final x = a.$2, y = b.$2;
    final c = x.category.index.compareTo(y.category.index);
    if (c != 0) return c;
    final l = (x.number.length > 6 ? 1 : 0).compareTo(y.number.length > 6 ? 1 : 0);
    return l != 0 ? l : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

final guidesProvider = FutureProvider<List<Guide>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  final all = parseSection(cache, 'guides', Guide.fromJson) ?? await ref.watch(contentRepositoryProvider).guides();
  final showDrafts = ref.watch(showDraftGuidesProvider);
  return all
      .where((g) => g.reviewStatus == ReviewStatus.approved || showDrafts)
      .toList(growable: false);
});
