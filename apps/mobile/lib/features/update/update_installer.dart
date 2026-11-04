import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/core/native/native_bridge.dart';
import 'package:joruri_bd/core/remote/app_meta.dart';

enum UpdateStage { idle, downloading, ready, needsPermission, failed }

class UpdateDownload {
  const UpdateDownload({this.stage = UpdateStage.idle, this.progress, this.path, this.versionCode = 0});

  final UpdateStage stage;

  /// 0..1 while downloading (null = size unknown).
  final double? progress;
  final String? path;
  final int versionCode;
}

/// Automatic updates. When the admins publish a new version (Firebase
/// `meta/app`, set by the release script), the app downloads the APK itself,
/// in the background on Wi-Fi or on a tap on mobile data, checks its SHA-256
/// against `meta/app`, and opens Android's installer: one tap on "Update".
/// (Android lets only app stores install silently.) If anything fails, the
/// banner offers the old way: download in the browser.
class UpdateInstaller extends Notifier<UpdateDownload> {
  bool _installAfterDownload = false;
  Future<void>? _running;

  @override
  UpdateDownload build() {
    ref.listen<UpdateInfo?>(updateInfoProvider, (_, next) {
      if (next != null) unawaited(_autoStart(next));
    }, fireImmediately: true);
    unawaited(_cleanUp());
    return const UpdateDownload();
  }

  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/updates');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// Deletes APKs of versions that are already installed.
  Future<void> _cleanUp() async {
    try {
      final info = await ref.read(packageInfoProvider.future);
      final current = baseBuildNumber(info.buildNumber);
      for (final f in (await _dir()).listSync().whereType<File>()) {
        final code = int.tryParse(RegExp(r'joruri-(\d+)').firstMatch(f.path)?.group(1) ?? '');
        if (code == null || code <= current || f.path.endsWith('.part')) f.deleteSync();
      }
    } catch (e) {
      AppLogger.info('Update clean-up skipped: $e');
    }
  }

  Future<void> _autoStart(UpdateInfo update) async {
    if (state.versionCode == update.meta.latestVersionCode && state.stage != UpdateStage.idle) return;
    // Already downloaded earlier (the app was closed before installing)?
    final file = File('${(await _dir()).path}/joruri-${update.meta.latestVersionCode}.apk');
    if (file.existsSync()) {
      final want = (await apkFor(update.meta)).sha256;
      if (want.isEmpty || await _sha256(file) == want) {
        state = UpdateDownload(stage: UpdateStage.ready, path: file.path, versionCode: update.meta.latestVersionCode);
        return;
      }
      file.deleteSync();
    }
    try {
      final net = await Connectivity().checkConnectivity();
      final unmetered = net.contains(ConnectivityResult.wifi) || net.contains(ConnectivityResult.ethernet);
      if (!unmetered) return; // on mobile data the person decides (banner button)
    } catch (_) {
      return;
    }
    await download(update);
  }

  /// Downloads [update] (if needed) and, when the person asked, opens the installer.
  Future<void> downloadAndInstall(UpdateInfo update) async {
    if (state.stage == UpdateStage.ready || state.stage == UpdateStage.needsPermission) {
      await install();
      return;
    }
    _installAfterDownload = true;
    await download(update);
  }

  Future<void> download(UpdateInfo update) => _running ??= _download(update).whenComplete(() => _running = null);

  Future<void> _download(UpdateInfo update) async {
    final code = update.meta.latestVersionCode;
    final apk = await apkFor(update.meta);
    final dir = await _dir();
    final part = File('${dir.path}/joruri-$code.apk.part');
    final done = File('${dir.path}/joruri-$code.apk');
    state = UpdateDownload(stage: UpdateStage.downloading, progress: 0, versionCode: code);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final req = await client.getUrl(apk.uri); // follows GitHub's redirect to its download server
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: apk.uri);
      final total = res.contentLength;
      var received = 0;
      var lastShown = 0.0;
      final sink = part.openWrite();
      try {
        await for (final chunk in res.timeout(const Duration(seconds: 60))) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final p = received / total;
            if (p - lastShown >= 0.01) {
              lastShown = p;
              state = UpdateDownload(stage: UpdateStage.downloading, progress: p, versionCode: code);
            }
          }
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && received != total) throw const HttpException('Download incomplete');
      if (apk.sha256.isNotEmpty && await _sha256(part) != apk.sha256) {
        throw const FormatException('The downloaded file does not match the published SHA-256');
      }
      if (done.existsSync()) done.deleteSync();
      part.renameSync(done.path);
      state = UpdateDownload(stage: UpdateStage.ready, path: done.path, versionCode: code);
      if (_installAfterDownload) await install();
    } catch (e, s) {
      AppLogger.error('Update download failed', e, s);
      if (part.existsSync()) part.deleteSync();
      state = UpdateDownload(stage: UpdateStage.failed, versionCode: code);
    } finally {
      client.close(force: true);
    }
  }

  /// Opens Android's installer. The first time Android asks the person to
  /// allow Joruri BD to install updates; after that it is one tap.
  Future<void> install() async {
    final path = state.path;
    if (path == null) return;
    _installAfterDownload = false;
    final native = ref.read(nativeBridgeProvider);
    switch (await native.installApk(path)) {
      case InstallStart.started:
        state = UpdateDownload(stage: UpdateStage.ready, path: path, versionCode: state.versionCode);
      case InstallStart.needsPermission:
        state = UpdateDownload(stage: UpdateStage.needsPermission, path: path, versionCode: state.versionCode);
        await native.openInstallSettings();
      case InstallStart.failed:
        state = UpdateDownload(stage: UpdateStage.failed, versionCode: state.versionCode);
    }
  }

  static Future<String> _sha256(File f) async => (await sha256.bind(f.openRead()).first).toString();
}

final updateInstallerProvider = NotifierProvider<UpdateInstaller, UpdateDownload>(UpdateInstaller.new);
