import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
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

  /// The donor switches their own availability on and off.
  Future<void> setAvailable(bool value) async {
    final current = state;
    if (current == null) return;
    await save(current.copyWith(available: value));
  }
}

/// This person in the donor search, when they chose to be listed.
final myDonorProvider = Provider<Donor?>((ref) => ref.watch(profileProvider)?.toDonor());
