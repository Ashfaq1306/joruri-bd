import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';

/// Result of putting the profile online. The profile is always saved on the
/// phone first; this only describes the online copy.
enum SyncStatus {
  /// Online features are not set up / Firebase unavailable.
  offlineOnly,

  /// Not signed in, so nothing is sent.
  signedOut,

  /// Server confirmed the write.
  synced,

  /// No answer in time (offline / slow). Will be retried.
  waitingForNetwork,

  /// The server rules refused it (e.g. rules still locked).
  notAllowed,

  /// Anything else. Will be retried.
  failed,
}

/// Writes the person's private profile (`users/{uid}`) and donor listing
/// (`donors/{uid}`).
///
/// Admin-controlled fields (`hidden`, `verified`) are never sent on update,
/// so a user can never change them; new listings start with both false.
/// Consent withdrawal sets `shareConsent: false` instead of deleting, so an
/// admin's moderation decision is never lost and cannot be undone by
/// re-registering. No transaction is used: it would need a server read and a
/// network connection; update-then-create gives the same guarantees with the
/// security rules doing the enforcement.
class ProfileSync {
  ProfileSync(this._ref);

  final Ref _ref;
  static const _timeout = Duration(seconds: 12);

  /// Fields the person owns on their donor listing. Used for updates.
  /// The rules allow exactly these keys to change.
  static Map<String, Object?> ownDonorFields(UserProfile p, String nowIso) => {
        'name': p.name,
        'bloodGroup': p.bloodGroup.label,
        'phone': p.phone,
        'districtId': p.districtId,
        'area': p.area,
        'available': p.listedAsDonor && p.available,
        'shareConsent': p.listedAsDonor,
        'updatedAt': nowIso,
      };

  /// A brand-new listing: own fields plus fixed starting values for the
  /// admin-controlled ones (the rules require exactly these).
  static Map<String, Object?> newDonorDocument(UserProfile p, String uid, String nowIso) => {
        ...ownDonorFields(p, nowIso),
        'id': uid,
        'uid': uid,
        'source': 'app',
        'hidden': false,
        'verified': false,
        'createdAt': nowIso,
      };

  Future<User?> _user() async {
    if (!await _ref.read(firebaseReadyProvider.future)) return null;
    return FirebaseAuth.instance.currentUser;
  }

  Future<SyncStatus> push(UserProfile? profile) async {
    try {
      if (!await _ref.read(firebaseReadyProvider.future)) return SyncStatus.offlineOnly;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return SyncStatus.signedOut;
      if (profile == null) return SyncStatus.synced;

      final db = FirebaseFirestore.instance;
      final now = DateTime.now().toUtc().toIso8601String();

      // 1. Private profile (owner-only).
      await db.doc('users/${user.uid}').set({...profile.toJson(), 'updatedAt': now}).timeout(_timeout);

      // 2. Donor listing.
      final donor = db.doc('donors/${user.uid}');
      try {
        await donor.update(ownDonorFields(profile, now)).timeout(_timeout);
      } on FirebaseException catch (e) {
        if (e.code != 'not-found') rethrow;
        // No listing yet. Create one only if the person opted in.
        if (profile.listedAsDonor) {
          await donor.set(newDonorDocument(profile, user.uid, now)).timeout(_timeout);
        }
      }
      return SyncStatus.synced;
    } on TimeoutException {
      // Firestore keeps the write queued and sends it when online; we still
      // report "waiting" and retry ourselves, because a queued update for a
      // listing that does not exist yet cannot create it.
      return SyncStatus.waitingForNetwork;
    } on FirebaseException catch (e) {
      AppLogger.error('Online profile write refused: ${e.code}', e);
      return switch (e.code) {
        'permission-denied' || 'unauthenticated' => SyncStatus.notAllowed,
        'unavailable' || 'deadline-exceeded' => SyncStatus.waitingForNetwork,
        _ => SyncStatus.failed,
      };
    } catch (e, s) {
      AppLogger.error('Online profile write failed', e, s);
      return SyncStatus.failed;
    }
  }

  /// "Delete my data". Removes the private profile. The donor listing is
  /// deleted when allowed; if an admin has hidden it, the rules keep it (so
  /// moderation cannot be undone) and it is switched off instead.
  /// Always signs out at the end.
  Future<void> removeAndSignOut() async {
    try {
      final user = await _user();
      if (user != null) {
        final db = FirebaseFirestore.instance;
        final donor = db.doc('donors/${user.uid}');
        try {
          await donor.delete().timeout(_timeout);
        } catch (_) {
          try {
            await donor.update({
              'shareConsent': false,
              'available': false,
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
            }).timeout(_timeout);
          } catch (_) {}
        }
        try {
          await db.doc('users/${user.uid}').delete().timeout(_timeout);
        } catch (_) {}
      }
    } catch (e, s) {
      AppLogger.error('Could not remove online profile', e, s);
    } finally {
      try {
        if (await _ref.read(firebaseReadyProvider.future)) await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }
}

final profileSyncProvider = Provider<ProfileSync>((ref) => ProfileSync(ref));
