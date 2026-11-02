import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/features/accident/presentation/accident_screen.dart';
import 'package:joruri_bd/features/blood/presentation/blood_group_screen.dart';
import 'package:joruri_bd/features/blood/presentation/donor_list_screen.dart';
import 'package:joruri_bd/features/coming_soon/presentation/coming_soon_screen.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_screen.dart';
import 'package:joruri_bd/features/directory/presentation/numbers_screen.dart';
import 'package:joruri_bd/features/guides/presentation/guide_detail_screen.dart';
import 'package:joruri_bd/features/hospitals/presentation/hospital_detail_screen.dart';
import 'package:joruri_bd/features/hospitals/presentation/hospitals_screen.dart';
import 'package:joruri_bd/features/pharmacy/presentation/pharmacy_screen.dart';
import 'package:joruri_bd/features/profile/presentation/profile_screen.dart';
import 'package:joruri_bd/features/profile/presentation/sign_in_screen.dart';
import 'package:joruri_bd/features/guides/presentation/guides_screen.dart';
import 'package:joruri_bd/features/home/presentation/home_screen.dart';
import 'package:joruri_bd/features/home/presentation/main_shell.dart';
import 'package:joruri_bd/features/onboarding/presentation/onboarding_screen.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/features/settings/presentation/settings_screen.dart';
import 'package:joruri_bd/features/sos/presentation/sos_countdown_screen.dart';
import 'package:joruri_bd/features/sos/presentation/sos_status_screen.dart';
import 'package:joruri_bd/features/toolkit/presentation/compass_screen.dart';
import 'package:joruri_bd/features/toolkit/presentation/location_screen.dart';
import 'package:joruri_bd/features/toolkit/presentation/toolkit_screen.dart';

/// Route map. SOS and every emergency screen sit outside the tab shell so
/// they open full-screen with nothing else competing for attention.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<bool>(
    settingsProvider.select((s) => s.onboardingDone),
    (_, __) => refresh.value++,
  );

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(settingsProvider).onboardingDone;
      final atOnboarding = state.matchedLocation == '/onboarding';
      // Sign-in is opened from inside onboarding, so allow it.
      if (!done && !atOnboarding && state.matchedLocation != '/sign-in') return '/onboarding';
      if (done && atOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/guides',
              builder: (_, state) {
                final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return GuidesScreen(key: ValueKey(tab), initialTab: tab);
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/sos', builder: (_, __) => const SosCountdownScreen()),
      GoRoute(path: '/sos/status', builder: (_, __) => const SosStatusScreen()),
      GoRoute(path: '/accident', builder: (_, __) => const AccidentScreen()),
      GoRoute(path: '/blood', builder: (_, __) => const BloodGroupScreen()),
      GoRoute(path: '/hospitals', builder: (_, __) => const HospitalsScreen()),
      GoRoute(
        path: '/hospital/:id',
        builder: (_, state) => HospitalDetailScreen(hospitalId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: '/pharmacy', builder: (_, __) => const PharmacyScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      // Old link from the SMS version.
      GoRoute(path: '/verify', redirect: (_, __) => '/sign-in'),
      GoRoute(path: '/blood/donors', builder: (_, __) => const DonorListScreen()),
      GoRoute(
        path: '/numbers/:category',
        builder: (_, state) => NumbersScreen(category: _category(state.pathParameters['category'])),
      ),
      GoRoute(
        path: '/guide/:id',
        builder: (_, state) => GuideDetailScreen(guideId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: '/toolkit', builder: (_, __) => const ToolkitScreen()),
      GoRoute(path: '/toolkit/compass', builder: (_, __) => const CompassScreen()),
      GoRoute(path: '/location', builder: (_, __) => const LocationScreen()),
      GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
      GoRoute(
        path: '/soon/:feature',
        builder: (_, state) => ComingSoonScreen(feature: state.pathParameters['feature'] ?? ''),
      ),
    ],
  );
});

NumberCategory? _category(String? name) {
  for (final c in NumberCategory.values) {
    if (c.name == name) return c;
  }
  return null;
}
