import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/announcements/announcements.dart';
import 'package:joruri_bd/features/home/presentation/home_screen.dart';
import 'package:joruri_bd/l10n/app_strings.dart';
import 'package:joruri_bd/l10n/strings_bn.dart';

Future<Widget> _home(String language, {List<Announcement> announcements = const []}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': language,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      networkStatusProvider.overrideWith((ref) => Stream.value(NetworkStatus.offline)),
      // No Firebase in widget tests: the app must work fully without it.
      firebaseReadyProvider.overrideWith((ref) async => false),
      announcementsProvider.overrideWith((ref) async => announcements),
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
      home: const HomeScreen(),
    ),
  );
}

/// A tall phone, so every Home section is on screen.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Home shows SOS and works with no internet', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _home('en'));
    await tester.pump();
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Road accident'), findsOneWidget);
    // No contacts yet, so Home invites the person to add one.
    expect(find.text('No emergency contact yet'), findsOneWidget);
  });

  testWidgets('Home renders in Bangla', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _home('bn'));
    await tester.pump();
    expect(find.text('জরুরি বিডি'), findsOneWidget);
    expect(find.text('অফলাইন'), findsOneWidget);
  });

  test('Bangla strings are really Bangla', () {
    const bn = StringsBn();
    final bangla = RegExp('[\u0980-\u09FF]');
    for (final text in [bn.appName, bn.sosHint, bn.call999, bn.whatToDoNow, bn.deleteLocalData]) {
      expect(bangla.hasMatch(text), isTrue, reason: text);
    }
  });

  testWidgets('An announcement from the admin website shows on Home', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(await _home('en', announcements: [
      Announcement.fromJson({
        'id': 'n1',
        'title': {'en': 'Blood camp on Friday', 'bn': ''},
        'body': {'en': 'Dhaka Medical College, 10am', 'bn': ''},
      }),
    ]));
    await tester.pump();
    await tester.pump();
    expect(find.text('Blood camp on Friday'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    // Info notices can be closed.
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.text('Blood camp on Friday'), findsNothing);
  });
}
