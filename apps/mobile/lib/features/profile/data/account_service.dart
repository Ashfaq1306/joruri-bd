import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';

enum DeleteResult { deleted, needsLogin, noInternet, failed }

/// How the person proves it is them again before the account is deleted.
enum LoginMethod { password, google, other }

/// Logging out and "Delete my data".
///
/// Logging out removes the person's own data from this phone (profile,
/// emergency contacts), after saving it with the account so that logging in
/// again brings it back. Phone settings (language, theme, alerts) stay.
///
/// Deleting removes everything: the account itself, the donor listing and
/// the profile online, and all app data on this phone.
class AccountService {
  AccountService(this._ref);

  final Ref _ref;

  /// Firebase asks for a fresh login before deleting an account; it allows
  /// about five minutes after logging in.
  static const _freshLogin = Duration(minutes: 4);

  Future<User?> _user() async {
    if (!await _ref.read(firebaseReadyProvider.future)) return null;
    return FirebaseAuth.instance.currentUser;
  }

  /// Saves the latest profile and contacts online before logging out.
  /// [SyncStatus.synced] when nothing is lost by logging out now.
  Future<SyncStatus> saveBeforeLogOut() async {
    if (_ref.read(profileProvider) == null) return SyncStatus.synced;
    return _ref.read(profileSyncStatusProvider.notifier).sync();
  }

  Future<void> logOut() async {
    await _ref.read(googleAuthProvider).signOut();
    await _ref.read(profileProvider.notifier).clearOnPhone();
    await _ref.read(contactsProvider.notifier).clearOnPhone();
    await _ref.read(profileSyncStatusProvider.notifier).clear();
  }

  Future<LoginMethod> loginMethod() async {
    final user = await _user();
    final providers = user?.providerData.map((p) => p.providerId).toSet() ?? const <String>{};
    if (providers.contains('password')) return LoginMethod.password;
    if (providers.contains('google.com')) return LoginMethod.google;
    return LoginMethod.other;
  }

  /// The e-mail address of the account, for the "confirm it's you" dialog.
  Future<String?> email() async => (await _user())?.email;

  /// Deletes the account and everything saved with it, then everything the
  /// app stored on this phone. Nothing is removed from the phone unless the
  /// online data is really gone (or there is no account).
  Future<DeleteResult> deleteEverything() async {
    final user = await _user();
    if (user != null) {
      final last = user.metadata.lastSignInTime;
      if (last == null || DateTime.now().difference(last) > _freshLogin) return DeleteResult.needsLogin;
      try {
        await _ref.read(profileSyncProvider).deleteOnline();
      } on TimeoutException {
        return DeleteResult.noInternet;
      } on FirebaseException catch (e) {
        AppLogger.error('Online data could not be deleted: ${e.code}', e);
        return e.code == 'unavailable' ? DeleteResult.noInternet : DeleteResult.failed;
      } catch (e, s) {
        AppLogger.error('Online data could not be deleted', e, s);
        return DeleteResult.failed;
      }
      try {
        await user.delete().timeout(const Duration(seconds: 20));
      } on FirebaseAuthException catch (e) {
        AppLogger.error('Account could not be deleted: ${e.code}', e);
        return switch (e.code) {
          'requires-recent-login' => DeleteResult.needsLogin,
          'network-request-failed' => DeleteResult.noInternet,
          _ => DeleteResult.failed,
        };
      } on TimeoutException {
        return DeleteResult.noInternet;
      } catch (e, s) {
        AppLogger.error('Account could not be deleted', e, s);
        return DeleteResult.failed;
      }
    }
    await _ref.read(googleAuthProvider).signOut();
    await _ref.read(sharedPreferencesProvider).clear();
    return DeleteResult.deleted;
  }

  /// After [deleteEverything]: the app starts again from the welcome screen
  /// (onboarding was reset too). Called once the screen has closed its
  /// dialogs, because the router leaves Settings right away.
  void restartApp() {
    _ref
      ..invalidate(contactsProvider)
      ..invalidate(profileProvider)
      ..invalidate(profileSyncStatusProvider)
      ..invalidate(settingsProvider);
  }
}

final accountServiceProvider = Provider<AccountService>((ref) => AccountService(ref));
