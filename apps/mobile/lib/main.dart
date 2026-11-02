import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/app.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/directory/data/content_sync.dart';
import 'package:joruri_bd/features/blood/data/donor_repository.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error('Flutter error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught error', error, stack);
    return true;
  };

  // Local storage is opened before the first frame so settings, language
  // and emergency contacts are ready instantly, with no loading screen.
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  runApp(UncontrolledProviderScope(container: container, child: const JoruriApp()));

  // Right after the first frame, read the bundled lists in the background,
  // so the first tap on Blood, Hospitals, Pharmacy or Guides opens instantly.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      container.read(emergencyNumbersProvider.future).ignore();
      container.read(guidesProvider.future).ignore();
      container.read(allDonorsProvider.future).ignore();
      container.read(hospitalsProvider.future).ignore();
      container.read(pharmaciesProvider.future).ignore();
    });
    // Check the admin website for new content now, and again whenever the
    // phone comes back online. Never blocks anything on screen.
    Future<void>.delayed(const Duration(seconds: 2), () => container.read(contentSyncProvider).run());
    container.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      if (next.valueOrNull == NetworkStatus.online && previous?.valueOrNull != NetworkStatus.online) {
        container.read(contentSyncProvider).run();
        // Finish a profile update that could not reach the server earlier.
        container.read(profileSyncStatusProvider.notifier).retryIfPending();
      }
    });
  });
}
