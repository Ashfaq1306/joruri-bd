import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/app/router.dart';
import 'package:joruri_bd/core/platform/location_service.dart';
import 'package:joruri_bd/features/location/location_prompt.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// A phone whose permission and location switch the test controls.
class _FakeLocation extends LocationService {
  _FakeLocation({required this.permitted, required this.switchOn, this.blocked = false});

  bool permitted;
  bool switchOn;
  bool blocked;
  bool grant = true;
  TurnOnResult answer = TurnOnResult.on;
  int permissionAsks = 0;
  int turnOnAsks = 0;
  int appSettingsOpened = 0;

  @override
  Future<LocationAccess> access() async {
    if (blocked) return LocationAccess.deniedForever;
    if (!permitted) return LocationAccess.denied;
    return switchOn ? LocationAccess.ready : LocationAccess.serviceOff;
  }

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    permitted = grant;
    return grant;
  }

  @override
  Future<TurnOnResult> turnOnService() async {
    turnOnAsks++;
    if (answer == TurnOnResult.on) switchOn = true;
    return answer;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;
}

Future<ProviderContainer> _app(
  WidgetTester tester,
  _FakeLocation location, {
  bool onboardingDone = true,
  String at = '/home',
}) async {
  SharedPreferences.setMockInitialValues({'settings.onboardingDone': onboardingDone, 'settings.language': 'en'});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Column(children: [HomeLocationBar(), Text('Home')]))),
      GoRoute(path: '/sos', builder: (_, __) => const Scaffold(body: Text('SOS countdown'))),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    locationServiceProvider.overrideWithValue(location),
    routerProvider.overrideWithValue(router),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('location switched off: the one-tap "turn on" dialog is asked for at once, no extra screen', (tester) async {
    final phone = _FakeLocation(permitted: true, switchOn: false);
    final c = await _app(tester, phone);
    await c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(phone.turnOnAsks, 1);
    expect(find.text('Allow location'), findsNothing);
    expect(c.read(locationAccessProvider), LocationAccess.ready);
    expect(find.text('Location is off: SOS cannot send where you are'), findsNothing);
  });

  testWidgets('no permission: a short reason first, then Android asks, then the switch is turned on', (tester) async {
    final phone = _FakeLocation(permitted: false, switchOn: false);
    final c = await _app(tester, phone);
    final done = c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(find.text('Allow Joruri BD to use your location'), findsOneWidget);
    expect(find.textContaining('never in the background'), findsOneWidget);
    await tester.tap(find.text('Allow location'));
    await tester.pumpAndSettle();
    await done;
    expect(phone.permissionAsks, 1);
    expect(phone.turnOnAsks, 1);
    expect(c.read(locationAccessProvider), LocationAccess.ready);
  });

  testWidgets('"Not now" is respected for the session; the Home bar still lets the person fix it', (tester) async {
    final phone = _FakeLocation(permitted: false, switchOn: true);
    final c = await _app(tester, phone);
    final prompt = c.read(locationPromptProvider);
    final first = prompt.check();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await first;
    expect(phone.permissionAsks, 0);
    expect(find.text('Location not allowed: SOS cannot send where you are'), findsOneWidget);

    // Opening the app again soon after: not asked again.
    await prompt.check();
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsNothing);

    // Tapping the Home bar asks again.
    await tester.tap(find.text('Location not allowed: SOS cannot send where you are'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow location'));
    await tester.pumpAndSettle();
    expect(phone.permissionAsks, 1);
    expect(find.text('Location not allowed: SOS cannot send where you are'), findsNothing);
  });

  testWidgets('"No thanks" on the turn-on dialog: Home shows that location is off', (tester) async {
    final phone = _FakeLocation(permitted: true, switchOn: false)..answer = TurnOnResult.declined;
    final c = await _app(tester, phone);
    await c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(phone.turnOnAsks, 1);
    expect(find.text('Location is off: SOS cannot send where you are'), findsOneWidget);
    await c.read(locationPromptProvider).check();
    expect(phone.turnOnAsks, 1, reason: 'not asked twice in a row');
  });

  testWidgets('blocked in the phone settings: explains where to allow it and opens the settings', (tester) async {
    final phone = _FakeLocation(permitted: false, switchOn: true, blocked: true);
    final c = await _app(tester, phone);
    final done = c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(find.text('Location is blocked for Joruri BD'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await done;
    expect(phone.appSettingsOpened, 1);
    expect(phone.permissionAsks, 0);
  });

  testWidgets('never in the way: nothing is asked on the SOS screen or before onboarding', (tester) async {
    final phone = _FakeLocation(permitted: false, switchOn: false);
    var c = await _app(tester, phone, at: '/sos');
    await c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsNothing);
    expect(phone.turnOnAsks, 0);

    // SOS pushed over Home, as the SOS button does.
    c = await _app(tester, phone);
    c.read(routerProvider).push('/sos');
    await tester.pumpAndSettle();
    expect(find.text('SOS countdown'), findsOneWidget);
    await c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsNothing);
    expect(phone.turnOnAsks, 0);

    c = await _app(tester, phone, onboardingDone: false);
    await c.read(locationPromptProvider).check();
    await tester.pumpAndSettle();
    expect(find.text('Allow location'), findsNothing);
    expect(phone.turnOnAsks, 0);
  });

  testWidgets('start() finishes its first check, so the notification question can follow', (tester) async {
    final phone = _FakeLocation(permitted: true, switchOn: true);
    final c = await _app(tester, phone);
    final prompt = c.read(locationPromptProvider)..start();
    await tester.pumpAndSettle();
    await prompt.firstCheckDone.timeout(const Duration(seconds: 1));
    expect(c.read(locationAccessProvider), LocationAccess.ready);
  });
}
