import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/app/router.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/core/native/native_bridge.dart';

enum EmailLinkResult { sent, signedIn, invalidEmail, emailMismatch, linkInvalid, tooMany, dailyLimit, unavailable, failed }

/// Sign-in with a link sent by e-mail (Firebase "email link"; SMS codes need
/// the paid Blaze plan). On the free Spark plan Firebase sends only 5 of
/// these e-mails a day for the whole project, so it is the backup to Google
/// sign-in, which has no such limit. Firebase sends the
/// e-mail; the link opens the app (Android App Links on
/// joruri-bd.firebaseapp.com, see AndroidManifest.xml), which finishes
/// signing in. If the link opens in a browser instead, the person can paste
/// it on the sign-in screen.
class EmailLinkAuth {
  EmailLinkAuth(this._ref);

  final Ref _ref;
  static const _pendingKey = 'auth.pendingEmail';
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// The e-mail address a link was last sent to from this phone.
  String? get pendingEmail => _ref.read(sharedPreferencesProvider).getString(_pendingKey);

  static bool looksLikeEmail(String s) => _email.hasMatch(s.trim());

  Future<EmailLinkResult> sendLink(String email, {required String languageCode}) async {
    email = email.trim();
    if (!looksLikeEmail(email)) return EmailLinkResult.invalidEmail;
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return EmailLinkResult.unavailable;
      final auth = FirebaseAuth.instance;
      await auth.setLanguageCode(languageCode);
      await auth
          .sendSignInLinkToEmail(
            email: email,
            actionCodeSettings: ActionCodeSettings(
              // Where a browser ends up if the app does not open (explains what to do).
              url: 'https://joruri-bd.web.app/signin/',
              handleCodeInApp: true,
              androidPackageName: 'bd.joruri.joruri_bd',
              androidInstallApp: false,
            ),
          )
          .timeout(const Duration(seconds: 20));
      await _ref.read(sharedPreferencesProvider).setString(_pendingKey, email);
      return EmailLinkResult.sent;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sending the sign-in e-mail failed: ${e.code}', e);
      if (e.code == 'invalid-email') return EmailLinkResult.invalidEmail;
      if (e.code == 'quota-exceeded') return EmailLinkResult.dailyLimit; // free plan: 5 e-mails a day
      if (e.code == 'too-many-requests') return EmailLinkResult.tooMany;
      return EmailLinkResult.failed;
    } catch (e, s) {
      AppLogger.error('Sending the sign-in e-mail failed', e, s);
      return EmailLinkResult.failed;
    }
  }

  Future<bool> isSignInLink(String link) async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return false;
      return FirebaseAuth.instance.isSignInWithEmailLink(link.trim());
    } catch (_) {
      return false;
    }
  }

  Future<EmailLinkResult> complete(String link, String email) async {
    email = email.trim();
    if (!looksLikeEmail(email)) return EmailLinkResult.invalidEmail;
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return EmailLinkResult.unavailable;
      if (!FirebaseAuth.instance.isSignInWithEmailLink(link.trim())) return EmailLinkResult.linkInvalid;
      await FirebaseAuth.instance
          .signInWithEmailLink(email: email, emailLink: link.trim())
          .timeout(const Duration(seconds: 20));
      await _ref.read(sharedPreferencesProvider).remove(_pendingKey);
      return EmailLinkResult.signedIn;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('E-mail link sign-in failed: ${e.code}', e);
      switch (e.code) {
        case 'invalid-email': // the address is well-formed (checked above): not the one the link was sent to
          return EmailLinkResult.emailMismatch;
        case 'invalid-action-code':
        case 'expired-action-code':
        case 'invalid-credential':
          return EmailLinkResult.linkInvalid;
        default:
          return EmailLinkResult.failed;
      }
    } catch (e, s) {
      AppLogger.error('E-mail link sign-in failed', e, s);
      return EmailLinkResult.failed;
    }
  }
}

final emailLinkAuthProvider = Provider<EmailLinkAuth>((ref) => EmailLinkAuth(ref));

/// A sign-in link that opened the app and is waiting to be used.
final pendingSignInLinkProvider = StateProvider<String?>((ref) => null);

/// Watches for sign-in links that open the app and shows the sign-in screen.
/// Kept alive by JoruriApp.
final signInLinkListenerProvider = Provider<void>((ref) {
  final native = ref.read(nativeBridgeProvider);
  final auth = ref.read(emailLinkAuthProvider);
  Future<void> handle(String? link) async {
    if (link == null || !await auth.isSignInLink(link)) return;
    ref.read(pendingSignInLinkProvider.notifier).state = link;
    final router = ref.read(routerProvider);
    if (router.routerDelegate.currentConfiguration.uri.path != '/sign-in') unawaited(router.push('/sign-in'));
  }

  unawaited(native.initialLink().then(handle));
  final sub = native.links.listen(handle);
  ref.onDispose(sub.cancel);
});
