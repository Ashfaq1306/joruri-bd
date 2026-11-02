import 'package:flutter/foundation.dart';

/// Central logging. Never pass names, phone numbers or coordinates here.
/// Phase 4 forwards errors to Crashlytics.
abstract final class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[info] $message');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[error] $message: ${error.runtimeType}');
    if (kDebugMode) {
      debugPrint('$error');
      if (stack != null) debugPrint('$stack');
    }
  }
}
