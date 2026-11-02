import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

/// Phone calls, within what Android and iOS allow.
class PhoneService {
  /// Opens the dialer with the number filled in; the person taps Call.
  /// Used for 999 (Android does not let apps place emergency calls
  /// directly) and for directory numbers.
  Future<bool> dial(String number) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (e, s) {
      AppLogger.error('Dial failed', e, s);
      return false;
    }
  }

  /// Android: calls immediately once the call permission is granted.
  /// iOS: always shows the system confirmation (cannot be bypassed).
  /// Any failure falls back to the dialer.
  Future<bool> callDirect(String number) async {
    if (!Platform.isAndroid) return dial(number);
    try {
      var status = await Permission.phone.status;
      if (!status.isGranted) status = await Permission.phone.request();
      if (!status.isGranted) return dial(number);
      await AndroidIntent(
        action: 'android.intent.action.CALL',
        data: Uri(scheme: 'tel', path: number).toString(),
      ).launch();
      return true;
    } catch (e, s) {
      AppLogger.error('Direct call failed', e, s);
      return dial(number);
    }
  }

  bool get supportsDirectCall => Platform.isAndroid;

  Future<bool> hasDirectCallPermission() async =>
      Platform.isAndroid && await Permission.phone.isGranted;

  Future<bool> requestDirectCallPermission() async =>
      Platform.isAndroid && (await Permission.phone.request()).isGranted;
}
