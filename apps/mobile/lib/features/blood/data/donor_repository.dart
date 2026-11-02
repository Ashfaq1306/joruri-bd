import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';

/// Donors your team provides, bundled in the app so the list works offline.
///
/// Fill assets/seed/donors.json with tool/import_donors.dart. In Phase 4
/// this also merges donors who register in the app (Firestore); screens
/// will not change.
class DonorRepository {
  DonorRepository(this._bundle);

  final AssetBundle _bundle;
  List<Donor>? _cache;

  Future<List<Donor>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final donors = [
      ...await _load('assets/seed/donors.json'),
      if (AppConfig.showDemoDonors) ...await _load('assets/seed/donors_demo.json'),
    ];
    return _cache = donors.where((d) => d.shareConsent).toList(growable: false);
  }

  Future<List<Donor>> _load(String path) async {
    try {
      final json = jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
      final out = <Donor>[];
      for (final item in (json['donors'] as List? ?? const [])) {
        try {
          out.add(Donor.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // One broken row must never hide every other donor.
        }
      }
      return out;
    } catch (e, s) {
      AppLogger.error('Donor list could not be read: $path', e, s);
      return const [];
    }
  }
}

final donorRepositoryProvider = Provider<DonorRepository>((ref) => DonorRepository(rootBundle));

final allDonorsProvider = FutureProvider<List<Donor>>((ref) => ref.watch(donorRepositoryProvider).all());
