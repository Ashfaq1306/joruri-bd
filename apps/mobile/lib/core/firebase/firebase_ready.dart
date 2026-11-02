import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/firebase_options.dart';

/// Firebase starts in the background, never before the first frame, so a
/// slow network or missing setup can never delay SOS. Everything online
/// waits on this; false means "online features not available" and the app
/// keeps working on the data stored on the phone.
final firebaseReadyProvider = FutureProvider<bool>((ref) async {
  if (Firebase.apps.isNotEmpty) return true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 15));
    return true;
  } catch (e) {
    // lib/firebase_options.dart may still be the placeholder. On Android the
    // Google Services Gradle plugin also provides the settings from
    // android/app/google-services.json, so try that before giving up.
    AppLogger.info('firebase_options.dart not usable ($e); trying google-services.json');
  }
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 15));
    return true;
  } catch (e, s) {
    AppLogger.error('Firebase not available', e, s);
    return false;
  }
});

/// The signed-in user (null when signed out or Firebase is unavailable).
final authUserProvider = StreamProvider<User?>((ref) async* {
  if (!await ref.watch(firebaseReadyProvider.future)) {
    yield null;
    return;
  }
  yield* FirebaseAuth.instance.authStateChanges();
});

/// True when someone is signed in (Google account). This proves only that
/// the person controls a Google account: it does NOT verify their identity,
/// their phone number or any medical information.
final signedInProvider = Provider<bool>(
  (ref) => ref.watch(authUserProvider).valueOrNull != null,
);
