import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/pharmacy/presentation/pharmacy_screen.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

Future<Widget> _screen(String language, {int tab = 0, List<Medicine> medicines = const []}) async {
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': true,
    'settings.language': language,
    'place.districtId': 'dhaka',
    'place.divisionId': 'dhaka',
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      networkStatusProvider.overrideWith((ref) => Stream.value(NetworkStatus.offline)),
      firebaseReadyProvider.overrideWith((ref) async => false),
      pharmaciesProvider.overrideWith((ref) async => const [
            Pharmacy(id: 't1', name: 'Team Night Pharmacy', districtId: 'dhaka', phone: '01000020001', open24h: true),
          ]),
      districtPharmaciesProvider.overrideWith((ref, d) async => [
            const Pharmacy(id: 't1', name: 'Team Night Pharmacy', districtId: 'dhaka', phone: '01000020001', open24h: true),
            Pharmacy(id: 'd1', name: 'Register Shop', districtId: 'dhaka', phone: '', area: 'Mirpur', address: 'Road 1',
                licenceValidUpto: DateTime(2020, 1, 1)),
          ]),
      medicinesProvider.overrideWith((ref) async => MedicineList(medicines, '2026-11-03')),
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
      home: PharmacyScreen(initialTab: tab),
    ),
  );
}

void main() {
  testWidgets('pharmacies: 24-hour team shop first, Directions when no phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await _screen('en'));
    await tester.pumpAndSettle();
    expect(find.text('2 pharmacies'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.textContaining('Licence expired 01-01-2020'), findsOneWidget);
    final team = tester.getTopLeft(find.text('Team Night Pharmacy')).dy;
    final reg = tester.getTopLeft(find.text('Register Shop')).dy;
    expect(team < reg, isTrue);
  });

  testWidgets('medicine search shows price and cheaper brand', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final meds = [
      Medicine(brand: 'Napa', generic: 'Paracetamol', strength: '500 mg', form: 'Tablet', company: 'Beximco',
          packs: const [MedicinePack('10 x 10', 1.2)]),
      Medicine(brand: 'Ace', generic: 'Paracetamol', strength: '500 mg', form: 'Tablet', company: 'Square',
          packs: const [MedicinePack('10 x 10', 1.0)]),
    ];
    await tester.pumpWidget(await _screen('bn', tab: 1, medicines: meds));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'napa');
    await tester.pumpAndSettle();
    expect(find.text('৳১.২০'), findsOneWidget);
    await tester.tap(find.text('Napa  500 mg'));
    await tester.pumpAndSettle();
    expect(find.text('সবচেয়ে কম দাম'), findsOneWidget); // Ace is cheaper
  });
}
