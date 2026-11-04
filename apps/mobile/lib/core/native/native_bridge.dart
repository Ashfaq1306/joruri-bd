import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

enum InstallStart { started, needsPermission, failed }

/// The app's own Android helpers (android/app/.../MainActivity.kt).
class NativeBridge {
  NativeBridge() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'link' && call.arguments is String) _links.add(call.arguments as String);
    });
  }

  static const _channel = MethodChannel('joruri/native');
  final _links = StreamController<String>.broadcast();

  /// Links (e-mail sign-in) that open the app while it is running.
  Stream<String> get links => _links.stream;

  /// The link the app was opened with, once (null when opened normally).
  Future<String?> initialLink() async {
    try {
      return await _channel.invokeMethod<String>('initialLink');
    } catch (_) {
      return null; // not Android, or an older build
    }
  }

  Future<bool> canInstallApks() async {
    try {
      return await _channel.invokeMethod<bool>('canInstallApks') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Android's "Install unknown apps" switch for Joruri BD (asked once).
  Future<void> openInstallSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallSettings');
    } catch (_) {}
  }

  /// Opens Android's installer for [path]; the person taps Update.
  Future<InstallStart> installApk(String path) async {
    try {
      final r = await _channel.invokeMethod<String>('installApk', {'path': path});
      return r == 'needsPermission' ? InstallStart.needsPermission : InstallStart.started;
    } catch (e, s) {
      AppLogger.error('Could not open the installer', e, s);
      return InstallStart.failed;
    }
  }
}

final nativeBridgeProvider = Provider<NativeBridge>((ref) => NativeBridge());
