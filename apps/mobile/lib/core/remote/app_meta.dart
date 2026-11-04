import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';

/// App-wide settings the admins change on the website (`meta/app`):
/// the latest app version with its download links, and content switches.
class AppMeta {
  const AppMeta({
    this.latestVersionCode = 0,
    this.latestVersionName = '',
    this.minVersionCode = 0,
    this.apkUrl = '',
    this.apkUrlArm32 = '',
    this.apkSha256 = '',
    this.apkSha256Arm32 = '',
    this.notes = const LocalizedText(en: '', bn: ''),
    this.showDraftGuides = AppConfig.showDraftGuides,
    this.showUnverifiedContent = AppConfig.showUnverifiedContent,
  });

  factory AppMeta.fromJson(Map<String, dynamic> j) {
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    String asString(Object? v) => v is String ? v.trim() : '';
    return AppMeta(
      latestVersionCode: asInt(j['latestVersionCode']),
      latestVersionName: asString(j['latestVersionName']),
      minVersionCode: asInt(j['minVersionCode']),
      apkUrl: asString(j['apkUrl']),
      apkUrlArm32: asString(j['apkUrlArm32']),
      apkSha256: asString(j['apkSha256']).toLowerCase(),
      apkSha256Arm32: asString(j['apkSha256Arm32']).toLowerCase(),
      notes: LocalizedText.fromJson(j['notes']),
      showDraftGuides: j['showDraftGuides'] is bool ? j['showDraftGuides'] as bool : AppConfig.showDraftGuides,
      showUnverifiedContent:
          j['showUnverifiedContent'] is bool ? j['showUnverifiedContent'] as bool : AppConfig.showUnverifiedContent,
    );
  }

  final int latestVersionCode;
  final String latestVersionName;

  /// Builds below this are told to update urgently (never blocks SOS).
  final int minVersionCode;
  final String apkUrl;
  final String apkUrlArm32;

  /// SHA-256 of each APK (set by tools/announce_release.mjs). The in-app
  /// updater installs only a download that matches; empty = not checked.
  final String apkSha256;
  final String apkSha256Arm32;
  final LocalizedText notes;
  final bool showDraftGuides;
  final bool showUnverifiedContent;
}

const _cacheKey = 'remote.appMeta';

/// Live copy of `meta/app`. Starts from the copy saved on the phone (so the
/// switches also apply offline), then follows the server in real time.
final appMetaProvider = StreamProvider<AppMeta>((ref) async* {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getString(_cacheKey);
  if (saved != null) {
    try {
      yield AppMeta.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      yield const AppMeta();
    }
  } else {
    yield const AppMeta();
  }

  if (!await ref.watch(firebaseReadyProvider.future)) return;
  final controller = StreamController<AppMeta>();
  final sub = FirebaseFirestore.instance.doc('meta/app').snapshots().listen(
    (snap) {
      final data = snap.data();
      if (data == null) return;
      final plain = <String, dynamic>{
        for (final e in data.entries)
          if (e.value is! Timestamp) e.key: e.value,
      };
      prefs.setString(_cacheKey, jsonEncode(plain));
      controller.add(AppMeta.fromJson(plain));
    },
    onError: (Object e, StackTrace s) => AppLogger.error('meta/app not readable (using saved copy)', e, s),
  );
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  yield* controller.stream;
});

/// Admin switches for what the app shows, with the built-in defaults.
final showDraftGuidesProvider = Provider<bool>(
  (ref) => ref.watch(appMetaProvider).valueOrNull?.showDraftGuides ?? AppConfig.showDraftGuides,
);
final showUnverifiedContentProvider = Provider<bool>(
  (ref) => ref.watch(appMetaProvider).valueOrNull?.showUnverifiedContent ?? AppConfig.showUnverifiedContent,
);

final packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Build number without the per-CPU offset that split APKs add
/// (Flutter adds 1000 × ABI code, e.g. 2012 for build 12 on arm64).
int baseBuildNumber(String buildNumber) => (int.tryParse(buildNumber) ?? 0) % 1000;

class UpdateInfo {
  const UpdateInfo({required this.versionName, required this.notes, required this.required, required this.meta});

  final String versionName;
  final LocalizedText notes;

  /// This build is below the minimum the admins still support.
  final bool required;
  final AppMeta meta;
}

/// Non-null when the admins published a newer build than this one.
final updateInfoProvider = Provider<UpdateInfo?>((ref) {
  final meta = ref.watch(appMetaProvider).valueOrNull;
  final info = ref.watch(packageInfoProvider).valueOrNull;
  if (meta == null || info == null || meta.apkUrl.isEmpty) return null;
  final current = baseBuildNumber(info.buildNumber);
  if (current == 0 || meta.latestVersionCode <= current) return null;
  return UpdateInfo(
    versionName: meta.latestVersionName.isEmpty ? '${meta.latestVersionCode}' : meta.latestVersionName,
    notes: meta.notes,
    required: current < meta.minVersionCode,
    meta: meta,
  );
});

/// The right APK for this phone: 64-bit for almost every phone, 32-bit for
/// old ones (only if the admins provided that link).
Future<Uri> apkUriFor(AppMeta meta) async => (await apkFor(meta)).uri;

/// The APK link for this phone and the SHA-256 it must have ('' = unknown).
Future<({Uri uri, String sha256})> apkFor(AppMeta meta) async {
  try {
    final abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
    if (!abis.contains('arm64-v8a') && !abis.contains('x86_64') && meta.apkUrlArm32.isNotEmpty) {
      return (uri: Uri.parse(meta.apkUrlArm32), sha256: meta.apkSha256Arm32);
    }
  } catch (_) {}
  return (uri: Uri.parse(meta.apkUrl), sha256: meta.apkSha256);
}

/// Asks the server for the newest `meta/app` (Settings → Check for updates).
/// Returns false when the server could not be reached.
Future<bool> refreshAppMeta(Ref ref) async {
  try {
    if (!await ref.read(firebaseReadyProvider.future)) return false;
    await FirebaseFirestore.instance
        .doc('meta/app')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    return true; // the live listener above picks up the change
  } catch (e) {
    AppLogger.info('Update check failed: $e');
    return false;
  }
}

final refreshAppMetaProvider = Provider<Future<bool> Function()>((ref) => () => refreshAppMeta(ref));
