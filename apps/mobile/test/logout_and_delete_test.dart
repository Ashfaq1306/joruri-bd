import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/profile/data/account_service.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';

const _me = UserProfile(name: 'Rahim', phone: '+8801711000000', bloodGroup: BloodGroup.oPos, districtId: 'dhaka');
const _amma = EmergencyContact(id: 'c1', name: 'Amma', phone: '+8801811000000');

/// The online copy, without Firebase.
class _FakeSync extends ProfileSync {
  _FakeSync(super.ref);

  final pushes = <List<EmergencyContact>>[];

  @override
  Future<SyncStatus> push(UserProfile? profile, {List<EmergencyContact> contacts = const []}) async {
    pushes.add(contacts);
    return SyncStatus.synced;
  }
}

Future<(ProviderContainer, SharedPreferences, _FakeSync)> _start({bool signedIn = true}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': 'bn',
    'profile.v1': jsonEncode(_me.toJson()),
    'contacts.v1': jsonEncode([_amma.toJson()]),
    'profile.syncPending': true,
  });
  final prefs = await SharedPreferences.getInstance();
  late _FakeSync sync;
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    // No Firebase in tests: sign-out and the account calls do nothing.
    firebaseReadyProvider.overrideWith((ref) async => false),
    signedInProvider.overrideWithValue(signedIn),
    profileSyncProvider.overrideWith((ref) => sync = _FakeSync(ref)),
  ]);
  addTearDown(container.dispose);
  container.read(profileSyncProvider);
  return (container, prefs, sync);
}

void main() {
  test('logging out removes my profile and contacts from the phone, keeps the phone settings', () async {
    final (c, prefs, sync) = await _start();
    expect(c.read(profileProvider)?.name, 'Rahim');
    expect(c.read(contactsProvider), hasLength(1));

    final account = c.read(accountServiceProvider);
    // The latest profile and contacts go online first, so logging in brings them back.
    expect(await account.saveBeforeLogOut(), SyncStatus.synced);
    expect(sync.pushes.last.single.name, 'Amma');

    await account.logOut();
    expect(c.read(profileProvider), isNull);
    expect(c.read(contactsProvider), isEmpty);
    expect(prefs.getString('profile.v1'), isNull);
    expect(prefs.getString('contacts.v1'), isNull);
    expect(prefs.getBool('profile.syncPending'), isNull);
    // Language and onboarding are phone settings, not personal data.
    expect(prefs.getString('settings.language'), 'bn');
    expect(c.read(settingsProvider).onboardingDone, isTrue);
  });

  test('a changed contact is saved with the account while logged in', () async {
    final (c, _, sync) = await _start();
    await c.read(contactsProvider.notifier).save(
          const EmergencyContact(id: 'c2', name: 'Abba', phone: '+8801911000000'),
        );
    await Future<void>.delayed(Duration.zero);
    expect(sync.pushes.last.map((e) => e.name), ['Amma', 'Abba']);
  });

  test('contacts are not sent anywhere when logged out', () async {
    final (c, _, sync) = await _start(signedIn: false);
    await c.read(contactsProvider.notifier).remove('c1');
    await Future<void>.delayed(Duration.zero);
    expect(sync.pushes, isEmpty);
  });

  test('delete my data (no account on this phone) wipes everything and restarts at welcome', () async {
    final (c, prefs, _) = await _start(signedIn: false);
    final account = c.read(accountServiceProvider);
    expect(await account.deleteEverything(), DeleteResult.deleted);
    account.restartApp();
    expect(prefs.getKeys(), isEmpty);
    expect(c.read(profileProvider), isNull);
    expect(c.read(contactsProvider), isEmpty);
    expect(c.read(settingsProvider).onboardingDone, isFalse);
  });

  test('restoring contacts never replaces contacts already on the phone', () async {
    final (c, _, _) = await _start();
    await c.read(contactsProvider.notifier).restore(const [
      EmergencyContact(id: 'x', name: 'Someone else', phone: '+8801511000000'),
    ]);
    expect(c.read(contactsProvider).single.name, 'Amma');
  });
}
