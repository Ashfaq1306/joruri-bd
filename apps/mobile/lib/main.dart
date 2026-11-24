import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/app.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/alerts/data/alert_notifications.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/directory/data/content_sync.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/features/blood/data/donor_repository.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/location/location_prompt.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
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
    // Also follow the website live, so an online phone gets a change within seconds.
    Future<void>.delayed(const Duration(seconds: 2), () {
      final sync = container.read(contentSyncProvider);
      sync.run();
      sync.watch();
    });
    // Like bKash: location off → Google's one-tap "Turn on location";
    // not allowed → a short reason, then Android's question.
    final locationPrompt = container.read(locationPromptProvider);
    Future<void>.delayed(const Duration(milliseconds: 800), locationPrompt.start);
    // Disaster alerts: follow the live list, show notifications, and ask once
    // (after onboarding) for permission to notify, after the location
    // question so two system dialogs never stack.
    Future<void>.delayed(const Duration(seconds: 3), () async {
      final alerts = container.read(alertNotificationsProvider);
      await alerts.start();
      if (container.read(settingsProvider).onboardingDone && container.read(alertSettingsProvider).notify) {
        await locationPrompt.firstCheckDone.timeout(const Duration(minutes: 2), onTimeout: () {});
        await alerts.askPermissionOnce();
      }
    });
    // Logged in but no profile on this phone (e.g. the app was reinstalled):
    // bring back the one saved with the account.
    container.listen<AsyncValue<Object?>>(authUserProvider, (_, next) {
      if (next.valueOrNull != null && container.read(profileProvider) == null) {
        container.read(profileProvider.notifier).restoreFromAccount().ignore();
      }
    }, fireImmediately: true);
    // A new user is asked right after finishing onboarding.
    container.listen<bool>(settingsProvider.select((s) => s.onboardingDone), (was, done) {
      if (done && was == false) {
        Future<void>.delayed(const Duration(seconds: 1), () async {
          // Onboarding asked for permission; the location switch may still be off.
          await container.read(locationPromptProvider).check();
          if (container.read(alertSettingsProvider).notify) {
            await container.read(alertNotificationsProvider).askPermissionOnce();
          }
        });
      }
    });
    container.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      if (next.valueOrNull == NetworkStatus.online && previous?.valueOrNull != NetworkStatus.online) {
        container.read(contentSyncProvider).run();
        // Finish a profile update that could not reach the server earlier.
        container.read(profileSyncStatusProvider.notifier).retryIfPending();
      }
    });
  });
}
