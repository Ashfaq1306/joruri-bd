import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';

enum SignInResult { signedIn, cancelled, unavailable, failed }

/// Google Sign-In → Firebase Authentication. Free on the Spark plan.
///
/// The Web client ID ("server client ID") lets Google issue the ID token
/// Firebase checks. It is read from android/app/google-services.json by the
/// Google Services plugin once Google sign-in is enabled in the console; it
/// can also be passed at build time:
///   flutter build apk --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
class GoogleAuth {
  GoogleAuth(this._ref);

  final Ref _ref;
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  Future<void>? _init;

  /// initialize() must run exactly once (google_sign_in 7.x).
  Future<void> _ensureInitialized() => _init ??= GoogleSignIn.instance.initialize(
        serverClientId: _webClientId.isEmpty ? null : _webClientId,
      );

  Future<SignInResult> signIn() async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return SignInResult.unavailable;
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) return SignInResult.unavailable;

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        AppLogger.error('Google sign-in returned no ID token (Web client ID missing in google-services.json?)');
        return SignInResult.unavailable;
      }
      await FirebaseAuth.instance
          .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
          .timeout(const Duration(seconds: 20));
      return SignInResult.signedIn;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return SignInResult.cancelled;
      AppLogger.error('Google sign-in failed: ${e.code}', e);
      return SignInResult.failed;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase sign-in failed: ${e.code}', e);
      return SignInResult.failed;
    } on TimeoutException catch (e) {
      AppLogger.error('Sign-in timed out', e);
      return SignInResult.failed;
    } catch (e, s) {
      // Unconfigured project (e.g. no Web client ID yet) ends up here.
      AppLogger.error('Sign-in not available', e, s);
      return SignInResult.unavailable;
    }
  }

  Future<void> signOut() async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return;
      await FirebaseAuth.instance.signOut();
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e, s) {
      AppLogger.error('Sign-out problem', e, s);
    }
  }
}

final googleAuthProvider = Provider<GoogleAuth>((ref) => GoogleAuth(ref));
