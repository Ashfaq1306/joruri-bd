import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_detail_screen.dart';
import 'package:joruri_bd/features/alerts/presentation/alerts_screen.dart';
import 'package:joruri_bd/features/alerts/presentation/home_alert_banner.dart';
import 'package:joruri_bd/features/alerts/presentation/storm_signals_screen.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

final _now = DateTime.now().toUtc();

final _cyclone = HazardAlert(
  id: 'bmd-test-cyclone',
  source: AlertSource.bmd,
  hazard: Hazard.cyclone,
  level: AlertLevel.emergency,
  headline: const LocalizedText(en: 'Severe cyclone likely to cross the coast', bn: 'প্রবল ঘূর্ণিঝড় উপকূল অতিক্রম করতে পারে'),
  instruction: const LocalizedText(en: 'Hoist great danger signal number ten (10).', bn: '১০ নম্বর মহাবিপদ সংকেত।'),
  districts: const ['coxs-bazar', 'chattogram'],
  sent: _now.subtract(const Duration(hours: 1)),
  expires: _now.add(const Duration(hours: 12)),
  signal: 10,
);

final _rainDhaka = HazardAlert(
  id: 'bmd-test-rain',
  source: AlertSource.bmd,
  hazard: Hazard.rain,
  level: AlertLevel.warning,
  headline: const LocalizedText(en: 'Heavy rainfall warning for Dhaka division', bn: 'ঢাকা বিভাগে ভারী বৃষ্টির সতর্কবার্তা'),
  districts: const ['dhaka', 'gazipur'],
  sent: _now.subtract(const Duration(hours: 2)),
  expires: _now.add(const Duration(hours: 20)),
);

final _expired = HazardAlert(
  id: 'bmd-old',
  source: AlertSource.bmd,
  hazard: Hazard.heat,
  level: AlertLevel.warning,
  headline: const LocalizedText(en: 'Old heat wave', bn: 'পুরোনো তাপপ্রবাহ'),
  districts: const ['dhaka'],
  sent: _now.subtract(const Duration(days: 3)),
  expires: _now.subtract(const Duration(days: 1)),
);

Future<List<Guide>> _bundledGuides() async {
  final json = jsonDecode(File('assets/seed/guides.json').readAsStringSync()) as Map<String, dynamic>;
  return [for (final g in json['guides'] as List) Guide.fromJson(g as Map<String, dynamic>)];
}

Future<Widget> _app(Widget home, String language, {List<HazardAlert> alerts = const [], String? district = 'dhaka'}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': language,
    if (district != null) 'alerts.districtId': district,
  });
  final prefs = await SharedPreferences.getInstance();
  final guides = await _bundledGuides();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      networkStatusProvider.overrideWith((ref) => Stream.value(NetworkStatus.offline)),
      firebaseReadyProvider.overrideWith((ref) async => false),
      alertFeedProvider.overrideWith((ref) => Stream.value(AlertFeed(official: alerts, checkedAt: _now))),
      guidesProvider.overrideWith((ref) async => guides),
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
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('alerts screen: my district first, the rest below, expired ones hidden', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const AlertsScreen(), 'en', alerts: [_cyclone, _rainDhaka, _expired]));
    await tester.pumpAndSettle();
    expect(find.text('Alerts for Dhaka'), findsOneWidget);
    expect(find.text('Heavy rainfall warning for Dhaka division'), findsOneWidget);
    expect(find.text('Elsewhere in Bangladesh'), findsOneWidget);
    expect(find.text('Severe cyclone likely to cross the coast'), findsOneWidget);
    expect(find.text('Old heat wave'), findsNothing);
    expect(find.text('Cyclone signals'), findsOneWidget);
    expect(find.text('Earthquake warning before shaking'), findsOneWidget);
  });

  testWidgets('alerts screen in Bangla with nothing for the district', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const AlertsScreen(), 'bn', alerts: [_cyclone]));
    await tester.pumpAndSettle();
    expect(find.text('এই মুহূর্তে ঢাকা-এর জন্য কোনো সতর্কবার্তা নেই।'), findsOneWidget);
    expect(find.text('প্রবল ঘূর্ণিঝড় উপকূল অতিক্রম করতে পারে'), findsOneWidget);
  });

  testWidgets('cyclone alert: signal meaning, official advice and what to do', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(AlertDetailScreen(alertId: _cyclone.id), 'en', alerts: [_cyclone]));
    await tester.pumpAndSettle();
    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(find.text('Signal 10'), findsOneWidget);
    expect(find.text('Signal 10: Great danger signal'), findsOneWidget);
    expect(find.textContaining('Go to a cyclone shelter or a strong concrete building now'), findsOneWidget);
    expect(find.textContaining('Official advice'), findsOneWidget);
    // Steps from the bundled cyclone guide, and a link to the full guide.
    expect(find.textContaining('Great danger signal (8, 9, 10)'), findsOneWidget);
    expect(find.text('Guide: Cyclone and storm surge'), findsOneWidget);
    expect(find.text('Call 999'), findsOneWidget);
  });

  testWidgets('earthquake report shows the after-shaking steps and says it was not predicted', (tester) async {
    _bigScreen(tester);
    final quake = UsgsQuakes.fromFeature({
      'id': 'q1',
      'properties': {'mag': 5.6, 'time': _now.subtract(const Duration(minutes: 20)).millisecondsSinceEpoch, 'place': '40 km E of Sylhet'},
      'geometry': {'coordinates': [92.2, 24.9, 12]},
    })!;
    await tester.pumpWidget(await _app(AlertDetailScreen(alertId: quake.id), 'en', alerts: [quake], district: 'sylhet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Earthquake of magnitude 5.6'), findsOneWidget);
    expect(find.textContaining('Expect aftershocks. Each time'), findsOneWidget);
    expect(find.textContaining('already happened'), findsOneWidget);
  });

  testWidgets('storm signals: all 11', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(await _app(const StormSignalsScreen(), 'bn'));
    await tester.pumpAndSettle();
    expect(find.text('১১'), findsOneWidget);
    expect(find.text('মহাবিপদ সংকেত'), findsNWidgets(3));
  });

  testWidgets('home banner only for my district', (tester) async {
    await tester.pumpWidget(await _app(const Scaffold(body: HomeAlertBanner()), 'en', alerts: [_cyclone]));
    await tester.pumpAndSettle();
    expect(find.textContaining('Severe cyclone'), findsNothing);

    await tester.pumpWidget(await _app(const Scaffold(body: HomeAlertBanner()), 'en', alerts: [_cyclone], district: 'coxs-bazar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Severe cyclone'), findsOneWidget);
    expect(find.text('Tap to see what to do'), findsOneWidget);
  });
}
