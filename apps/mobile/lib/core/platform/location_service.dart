import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/core/native/native_bridge.dart';

enum LocationIssue { none, serviceOff, denied, deniedForever, unavailable }

/// Whether SOS could read the location right now, without asking anything.
enum LocationAccess { ready, serviceOff, denied, deniedForever }

/// Result of asking to turn location on.
enum TurnOnResult { on, declined, openedSettings }

class LocationResult {
  const LocationResult(this.location, this.issue);

  final SosLocation? location;
  final LocationIssue issue;
}

/// GPS access. Works with no internet. Never tracks in the background:
/// location is read only when SOS runs or the location screen is open.
class LocationService {
  LocationService({NativeBridge? native}) : _native = native;

  final NativeBridge? _native;
  static const _recentEnough = Duration(minutes: 2);

  /// Fast path: a fix from the last 2 minutes is used at once.
  /// Otherwise waits up to [timeout] for a fresh fix, then falls back to
  /// the last known position (the SOS message then says how old it is).
  Future<LocationResult> current({
    Duration timeout = const Duration(seconds: 10),
    bool askPermission = true,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(null, LocationIssue.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(null, LocationIssue.deniedForever);
      }

      final last = await _lastKnown();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationResult(last, LocationIssue.serviceOff);
      }
      if (last != null && DateTime.now().difference(last.fixTime) < _recentEnough) {
        return LocationResult(last, LocationIssue.none);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
        );
        return LocationResult(_toSos(position), LocationIssue.none);
      } on TimeoutException {
        return LocationResult(last, last == null ? LocationIssue.unavailable : LocationIssue.none);
      }
    } catch (e, s) {
      AppLogger.error('Location failed', e, s);
      return const LocationResult(null, LocationIssue.unavailable);
    }
  }

  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<bool> requestPermission() async {
    final p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Permission first, then the location switch. Never shows a dialog.
  Future<LocationAccess> access() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.deniedForever) return LocationAccess.deniedForever;
      if (p == LocationPermission.denied || p == LocationPermission.unableToDetermine) return LocationAccess.denied;
      return await Geolocator.isLocationServiceEnabled() ? LocationAccess.ready : LocationAccess.serviceOff;
    } catch (e, s) {
      AppLogger.error('Location check failed', e, s);
      return LocationAccess.ready; // never nag because of a failed check
    }
  }

  /// Asks to turn the phone's location on: Google's one-tap
  /// "Turn on device location" dialog on Android (like bKash), otherwise
  /// the phone's location settings.
  Future<TurnOnResult> turnOnService() async {
    final answer = await _native?.enableLocation();
    if (answer == LocationSwitch.on) return TurnOnResult.on;
    if (answer == LocationSwitch.declined) return TurnOnResult.declined;
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
    return TurnOnResult.openedSettings;
  }

  /// Kept for the buttons on the SOS and location screens: now tries the
  /// one-tap dialog first.
  Future<void> openLocationSettings() => turnOnService();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<SosLocation?> _lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : _toSos(p);
    } catch (_) {
      return null;
    }
  }

  SosLocation _toSos(Position p) => SosLocation(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyMeters: p.accuracy,
        fixTime: p.timestamp,
      );
}
