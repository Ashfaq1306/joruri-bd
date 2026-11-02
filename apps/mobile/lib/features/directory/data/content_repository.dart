import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/config/app_config.dart';
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
/// while [AppConfig.showUnverifiedContent] is on, and always carry a label.
final emergencyNumbersProvider = FutureProvider<List<EmergencyNumber>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  final all = parseSection(cache, 'numbers', EmergencyNumber.fromJson) ??
      await ref.watch(contentRepositoryProvider).numbers();
  return all
      .where((n) => n.verification.isVerified || AppConfig.showUnverifiedContent)
      .toList(growable: false);
});

final guidesProvider = FutureProvider<List<Guide>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  final all = parseSection(cache, 'guides', Guide.fromJson) ?? await ref.watch(contentRepositoryProvider).guides();
  return all
      .where((g) =>
          g.reviewStatus == ReviewStatus.approved || AppConfig.showDraftGuides)
      .toList(growable: false);
});
