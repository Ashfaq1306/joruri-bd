import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/core/firebase/email_link_auth.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';

enum PasswordResult {
  signedIn,
  resetSent,
  invalidEmail,
  weakPassword,
  wrongPassword,
  emailInUse,
  tooMany,
  unavailable,
  noInternet,
  failed,
}

/// Accounts with an e-mail address and a password (Firebase "Email/Password",
/// free on the Spark plan with no daily limit). Created once, then used to
/// log in on any phone; Firebase keeps the person logged in on this phone
/// until they sign out.
class PasswordAuth {
  PasswordAuth(this._ref);

  final Ref _ref;
  static const minLength = 6;
  static const _timeout = Duration(seconds: 20);

  Future<PasswordResult> create(String email, String password) =>
      _run(email, password, (auth, e, p) => auth.createUserWithEmailAndPassword(email: e, password: p));

  Future<PasswordResult> logIn(String email, String password) =>
      _run(email, password, (auth, e, p) => auth.signInWithEmailAndPassword(email: e, password: p));

  /// Proves again that it is the account owner (Firebase asks for this
  /// before an account is deleted).
  Future<PasswordResult> confirm(String password) async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return PasswordResult.unavailable;
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) return PasswordResult.failed;
      await user
          .reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password))
          .timeout(_timeout);
      return PasswordResult.signedIn;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password check failed: ${e.code}', e);
      return _map(e.code);
    } on TimeoutException {
      return PasswordResult.noInternet;
    } catch (e, s) {
      AppLogger.error('Password check failed', e, s);
      return PasswordResult.failed;
    }
  }

  /// E-mails a link to choose a new password. Also how someone who used to
  /// sign in with an e-mail link (no password yet) sets one.
  Future<PasswordResult> sendReset(String email, {required String languageCode}) async {
    email = email.trim();
    if (!EmailLinkAuth.looksLikeEmail(email)) return PasswordResult.invalidEmail;
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return PasswordResult.unavailable;
      await FirebaseAuth.instance.setLanguageCode(languageCode);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email).timeout(_timeout);
      return PasswordResult.resetSent;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password reset e-mail failed: ${e.code}', e);
      return _map(e.code);
    } on TimeoutException {
      return PasswordResult.noInternet;
    } catch (e, s) {
      AppLogger.error('Password reset e-mail failed', e, s);
      return PasswordResult.failed;
    }
  }

  Future<PasswordResult> _run(
    String email,
    String password,
    Future<UserCredential> Function(FirebaseAuth auth, String email, String password) action,
  ) async {
    email = email.trim();
    if (!EmailLinkAuth.looksLikeEmail(email)) return PasswordResult.invalidEmail;
    if (password.length < minLength) return PasswordResult.weakPassword;
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return PasswordResult.unavailable;
      await action(FirebaseAuth.instance, email, password).timeout(_timeout);
      return PasswordResult.signedIn;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('E-mail and password sign-in failed: ${e.code}', e);
      return _map(e.code);
    } on TimeoutException {
      return PasswordResult.noInternet;
    } catch (e, s) {
      AppLogger.error('E-mail and password sign-in failed', e, s);
      return PasswordResult.failed;
    }
  }

  static PasswordResult _map(String code) => switch (code) {
        'invalid-email' => PasswordResult.invalidEmail,
        'weak-password' => PasswordResult.weakPassword,
        // With e-mail enumeration protection on, a wrong password and an
        // unknown address both come back as invalid-credential.
        'wrong-password' || 'user-not-found' || 'invalid-credential' || 'invalid-login-credentials' =>
          PasswordResult.wrongPassword,
        'email-already-in-use' => PasswordResult.emailInUse,
        'too-many-requests' => PasswordResult.tooMany,
        'network-request-failed' => PasswordResult.noInternet,
        'operation-not-allowed' => PasswordResult.unavailable,
        _ => PasswordResult.failed,
      };
}

final passwordAuthProvider = Provider<PasswordAuth>((ref) => PasswordAuth(ref));
