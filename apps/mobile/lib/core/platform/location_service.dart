import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

enum LocationIssue { none, serviceOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult(this.location, this.issue);

  final SosLocation? location;
  final LocationIssue issue;
}

/// GPS access. Works with no internet. Never tracks in the background:
/// location is read only when SOS runs or the location screen is open.
class LocationService {
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

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

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
