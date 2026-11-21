import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/features/directory/presentation/numbers_screen.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/profile/presentation/sign_in_screen.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

const _savedContacts = [EmergencyContact(id: 'c1', name: 'Amma', phone: '+8801811000000')];
const _saved = UserProfile(name: 'Rahim', phone: '+8801711000000', bloodGroup: BloodGroup.oPos, districtId: 'chattogram');

/// The online copy of the profile, without Firebase.
class _FakeSync extends ProfileSync {
  _FakeSync(super.ref, this.online);

  final AccountCopy? online;
  int pulls = 0;
  List<EmergencyContact>? pushedContacts;

  @override
  Future<AccountCopy?> pull() async {
    pulls++;
    return online;
  }

  @override
  Future<SyncStatus> push(UserProfile? profile, {List<EmergencyContact> contacts = const []}) async {
    pushedContacts = contacts;
    return SyncStatus.synced;
  }
}

List<EmergencyNumber> _bundledNumbers() {
  final json = jsonDecode(File('assets/seed/emergency_numbers.json').readAsStringSync()) as Map<String, dynamic>;
  return sortEmergencyNumbers([
    for (final n in json['numbers'] as List) EmergencyNumber.fromJson(n as Map<String, dynamic>),
  ]);
}

Future<Widget> _app(Widget home, {String language = 'en', String? homeDistrict}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': language,
    if (homeDistrict != null)
      'profile.v1': jsonEncode(UserProfile(
              name: 'Test', phone: '+8801711000000', bloodGroup: BloodGroup.aPos, districtId: homeDistrict)
          .toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      networkStatusProvider.overrideWith((ref) => Stream.value(NetworkStatus.offline)),
      firebaseReadyProvider.overrideWith((ref) async => true),
      authUserProvider.overrideWith((ref) => Stream<User?>.value(null)),
      emergencyNumbersProvider.overrideWith((ref) async => _bundledNumbers()),
    ],
    child: MaterialApp(
      locale: Locale(language),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('log in is the default; create account asks for the password twice', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const SignInScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Password again'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    expect(find.text('Password again'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
  });

  testWidgets('the form is checked before anything is sent', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const SignInScreen(startWithCreate: true)));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);

    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a valid e-mail address'), findsOneWidget);

    await tester.enterText(fields.at(0), 'rahim@example.com');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 6 characters for the password.'), findsWidgets);

    await tester.enterText(fields.at(1), 'secret123');
    await tester.enterText(fields.at(2), 'secret124');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('The two passwords are not the same.'), findsOneWidget);
  });

  test('logging in on a new phone brings back the saved profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late _FakeSync sync;
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseReadyProvider.overrideWith((ref) async => false),
      profileSyncProvider.overrideWith((ref) => sync = _FakeSync(ref, const AccountCopy(_saved, _savedContacts))),
    ]);
    addTearDown(container.dispose);

    expect(container.read(profileProvider), isNull);
    expect(await container.read(profileProvider.notifier).restoreFromAccount(), isTrue);
    expect(container.read(profileProvider)?.name, 'Rahim');
    expect(prefs.getString('profile.v1'), contains('Rahim'));
    expect(container.read(contactsProvider).single.name, 'Amma');
    // A profile already on the phone is never replaced.
    expect(await container.read(profileProvider.notifier).restoreFromAccount(), isFalse);
    expect(sync.pulls, 1);
  });

  testWidgets('ambulance services are grouped by city, my district first', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const NumbersScreen(category: NumberCategory.ambulance), homeDistrict: 'khulna'));
    await tester.pumpAndSettle();
    expect(find.text('National Emergency Service'), findsOneWidget);
    expect(find.text('Ambulance services by city'), findsOneWidget);
    expect(find.text('your district'), findsOneWidget);
    // Khulna (my district) comes before Dhaka.
    final khulna = tester.getTopLeft(find.text('Khulna').first).dy;
    final dhaka = tester.getTopLeft(find.text('Dhaka').first).dy;
    expect(khulna, lessThan(dhaka));
    expect(find.text('Gazi Medical College Hospital'), findsOneWidget);
    expect(find.text('Other numbers'), findsWidgets);
  });

  testWidgets('the list of all numbers links to ambulances instead of listing them', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const NumbersScreen(category: null)));
    await tester.pumpAndSettle();
    expect(find.text('Ambulance services by city'), findsOneWidget);
    expect(find.text('Labaid Hospital'), findsNothing);
  });

  test('bundled ambulance numbers: local, mobile numbers, unverified', () {
    final ambulances = _bundledNumbers().where((n) => n.isLocal).toList();
    expect(ambulances.length, greaterThanOrEqualTo(30));
    for (final a in ambulances) {
      expect(a.category, NumberCategory.ambulance);
      expect(BdLocations.district(a.districtId!), isNotNull, reason: a.id);
      for (final n in [a.number, ...a.otherNumbers]) {
        expect(n, matches(RegExp(r'^01[3-9]\d{8}$')), reason: a.id);
      }
      expect(a.verification.isVerified, isFalse);
    }
    // "Whole country" saved by the admin website is not a district.
    final national = EmergencyNumber.fromJson({
      'id': 'x', 'number': '999', 'category': 'national', 'districtId': '',
      'name': {'en': 'a', 'bn': 'a'}, 'description': {'en': '', 'bn': ''}, 'address': {'en': '', 'bn': ''},
    });
    expect(national.isLocal, isFalse);
    expect(national.address, isNull);
  });
}
