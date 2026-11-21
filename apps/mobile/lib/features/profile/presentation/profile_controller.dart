import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/profile/data/profile_repository.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final profileProvider = NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);

class ProfileController extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => ref.watch(profileRepositoryProvider).load();

  /// Saves on the phone (always works, also offline) and starts updating the
  /// online copy in the background. The online result is tracked by
  /// [profileSyncStatusProvider], which never throws and retries later.
  Future<void> save(UserProfile profile) async {
    state = profile;
    await ref.read(profileRepositoryProvider).save(profile);
    unawaited(ref.read(profileSyncStatusProvider.notifier).sync());
  }

  /// Same as [save] but waits for the online result, for screens that show it.
  Future<SyncStatus> saveAndSync(UserProfile profile) async {
    state = profile;
    await ref.read(profileRepositoryProvider).save(profile);
    return ref.read(profileSyncStatusProvider.notifier).sync();
  }

  Future<bool>? _restoring;

  /// After logging in on a phone with no profile yet (new phone, app
  /// reinstalled, logged out before): brings back the profile and the
  /// emergency contacts saved with the account, so the person never has to
  /// fill them in again. True when a profile was restored.
  Future<bool> restoreFromAccount() => _restoring ??= _restore().whenComplete(() => _restoring = null);

  Future<bool> _restore() async {
    if (state != null) return false;
    final online = await ref.read(profileSyncProvider).pull();
    // Something typed on the phone meanwhile wins.
    if (online == null || state != null) return false;
    state = online.profile;
    await ref.read(profileRepositoryProvider).save(online.profile);
    if (online.contacts.isNotEmpty) await ref.read(contactsProvider.notifier).restore(online.contacts);
    ref.read(profileSyncStatusProvider.notifier).markSynced();
    return true;
  }

  /// Removes the profile from this phone (logging out, deleting the data).
  Future<void> clearOnPhone() async {
    state = null;
    await ref.read(profileRepositoryProvider).clear();
  }

  /// The donor switches their own availability on and off.
  Future<void> setAvailable(bool value) async {
    final current = state;
    if (current == null) return;
    await save(current.copyWith(available: value));
  }
}

/// This person in the donor search, when they chose to be listed.
final myDonorProvider = Provider<Donor?>((ref) => ref.watch(profileProvider)?.toDonor());
