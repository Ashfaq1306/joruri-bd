import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';

class ProfileSyncState {
  const ProfileSyncState(this.status, {this.running = false, this.at});

  final SyncStatus status;
  final bool running;
  final DateTime? at;
}

/// Tracks whether the online copy of the profile is up to date, separately
/// from the local save. Remembers an unfinished sync across restarts and
/// retries it when the phone is online again.
final profileSyncStatusProvider =
    NotifierProvider<ProfileSyncController, ProfileSyncState>(ProfileSyncController.new);

class ProfileSyncController extends Notifier<ProfileSyncState> {
  static const _pendingKey = 'profile.syncPending';

  @override
  ProfileSyncState build() {
    final pending = ref.read(sharedPreferencesProvider).getBool(_pendingKey) ?? false;
    return ProfileSyncState(pending ? SyncStatus.waitingForNetwork : SyncStatus.signedOut);
  }

  bool get hasPending => ref.read(sharedPreferencesProvider).getBool(_pendingKey) ?? false;

  /// Never throws. Returns the outcome so screens can show it.
  Future<SyncStatus> sync() async {
    if (state.running) return state.status;
    state = ProfileSyncState(state.status, running: true, at: state.at);
    SyncStatus result;
    try {
      result = await ref.read(profileSyncProvider).push(ref.read(profileProvider));
    } catch (_) {
      result = SyncStatus.failed;
    }
    // Refused (rules still locked) is retried too, so profiles go online by
    // themselves once the proposed rules are deployed.
    final retry = result == SyncStatus.waitingForNetwork || result == SyncStatus.failed || result == SyncStatus.notAllowed;
    try {
      await ref.read(sharedPreferencesProvider).setBool(_pendingKey, retry);
    } catch (_) {}
    state = ProfileSyncState(result, at: DateTime.now());
    return result;
  }

  /// Retry an unfinished sync (called when the phone comes back online).
  Future<void> retryIfPending() async {
    if (hasPending) await sync();
  }

  void reset() => state = const ProfileSyncState(SyncStatus.signedOut);
}
