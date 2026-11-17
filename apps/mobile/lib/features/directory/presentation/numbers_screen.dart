import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Emergency numbers for one category (police, fire, ambulance) or all.
class NumbersScreen extends ConsumerWidget {
  const NumbersScreen({super.key, required this.category});

  final NumberCategory? category;

  String _title(AppStrings s) => switch (category) {
        NumberCategory.police => s.tilePolice,
        NumberCategory.fire => s.tileFire,
        NumberCategory.ambulance => s.tileAmbulance,
        _ => s.emergencyNumbers,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final async = ref.watch(emergencyNumbersProvider);
    final filter = category;
    final showsPolice = filter == null || filter == NumberCategory.police;
    final showsFire = filter == null || filter == NumberCategory.fire;
    final ambulanceScreen = filter == NumberCategory.ambulance;

    return Scaffold(
      appBar: GlassAppBar(title: Text(_title(s))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Fallback(message: s.genericError),
        data: (all) {
          // Local services (ambulances in one city) are listed by city on
          // the ambulance screen, not among the national numbers.
          final list = [for (final n in all) if (!n.isLocal && (filter == null || n.serves(filter))) n];
          final ambulances = [for (final n in all) if (n.isLocal && n.category == NumberCategory.ambulance) n];
          if (list.isEmpty && (!ambulanceScreen || ambulances.isEmpty)) return _Fallback(message: s.noNumbers);
          return ListView(
            padding: const EdgeInsets.all(JSpace.md),
            children: [
              for (final n in list) ...[
                NumberCard(number: n),
                const SizedBox(height: 12),
                // Right after 999: every thana with the OC's number, and
                // every fire station with its number.
                if (n.number == AppConfig.nationalEmergencyNumber) ...[
                  if (showsPolice) ...[
                    const _StationsLink(service: StationService.police),
                    const SizedBox(height: 12),
                  ],
                  if (showsFire) ...[
                    const _StationsLink(service: StationService.fire),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
              if (!list.any((n) => n.number == AppConfig.nationalEmergencyNumber)) ...[
                if (showsPolice) const _StationsLink(service: StationService.police),
                if (showsFire) const _StationsLink(service: StationService.fire),
              ],
              if (filter == null && ambulances.isNotEmpty) ...[
                const SizedBox(height: 12),
                _AmbulancesLink(count: ambulances.length),
              ],
              if (ambulanceScreen)
                if (ambulances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
                    child: Text(s.localNumbersPending, style: Theme.of(context).textTheme.bodyMedium),
                  )
                else
                  ..._ambulanceSections(context, ref, ambulances),
            ],
          );
        },
      ),
    );
  }
}

/// Ambulance services grouped by city, the person's own district first.
List<Widget> _ambulanceSections(BuildContext context, WidgetRef ref, List<EmergencyNumber> ambulances) {
  final s = context.s;
  final theme = Theme.of(context);
  final lang = s.languageCode;
  final home = ref.watch(profileProvider)?.districtId;
  final byDistrict = <String, List<EmergencyNumber>>{};
  for (final a in ambulances) {
    byDistrict.putIfAbsent(a.districtId!, () => []).add(a);
  }
  final order = byDistrict.keys.toList()
    ..sort((a, b) {
      if (a == home) return -1;
      if (b == home) return 1;
      return byDistrict[b]!.length.compareTo(byDistrict[a]!.length);
    });
  return [
    const SizedBox(height: JSpace.sm),
    Text(s.ambulanceServices, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: JSpace.xs),
    Text(s.ambulanceListNote, style: theme.textTheme.bodyMedium),
    for (final d in order) ...[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, JSpace.lg, 4, JSpace.sm),
        child: Row(
          children: [
            const Icon(Icons.location_city, size: 20, color: JColors.ambulance),
            const SizedBox(width: 8),
            Text(BdLocations.district(d)?.name(lang) ?? d,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (d == home) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: JColors.ambulance.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(s.yourDistrictTag,
                    style: theme.textTheme.labelMedium?.copyWith(color: JColors.ambulance, fontWeight: FontWeight.w700)),
              ),
            ],
            const Spacer(),
            Text(localizedDigits('${byDistrict[d]!.length}', lang), style: theme.textTheme.labelLarge),
          ],
        ),
      ),
      for (final a in byDistrict[d]!) ...[
        NumberCard(number: a),
        const SizedBox(height: 12),
      ],
    ],
  ];
}

/// On the list of all numbers: opens the ambulance services by city.
class _AmbulancesLink extends StatelessWidget {
  const _AmbulancesLink({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Material(
      color: JColors.ambulance,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/numbers/ambulance'),
        child: Padding(
          padding: const EdgeInsets.all(JSpace.md),
          child: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.white, size: 36),
              const SizedBox(width: JSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.ambulanceServices,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(localizedDigits(s.ambulanceServicesCount(count), s.languageCode),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(220))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the list of every police station with the OC's number, or of
/// every fire station with its number.
class _StationsLink extends ConsumerWidget {
  const _StationsLink({required this.service});

  final StationService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final fire = service == StationService.fire;
    final count = ref.watch(stationsProvider(service)).valueOrNull?.length;
    return Material(
      color: fire ? JColors.fire : JColors.police,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(fire ? '/fire-stations' : '/police-stations'),
        child: Padding(
          padding: const EdgeInsets.all(JSpace.md),
          child: Row(
            children: [
              Icon(fire ? Icons.local_fire_department : Icons.local_police, color: Colors.white, size: 36),
              const SizedBox(width: JSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fire ? s.findLocalFire : s.findLocalPolice,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    if (count != null && count > 0)
                      Text(localizedDigits(fire ? s.findLocalFireSub(count) : s.findLocalPoliceSub(count), s.languageCode),
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(220))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// If content cannot load, 999 is still one tap away.
class _Fallback extends ConsumerWidget {
  const _Fallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(JSpace.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: JSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
            onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            icon: const Icon(Icons.call),
            label: Text(context.s.call999),
          ),
        ],
      ),
    );
  }
}

/// One verified (or clearly labelled) emergency number with a big call button.
class NumberCard extends ConsumerWidget {
  const NumberCard({super.key, required this.number});

  final EmergencyNumber number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final lang = s.languageCode;
    final v = number.verification;
    final sourceUrl = v.sourceUrl;
    final isNational = number.category == NumberCategory.national;

    return Container(
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? JColors.nightSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(140)),
        boxShadow: JShadows.soft(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Short codes (999) sit beside the name; full numbers get their own line.
          if (number.number.length <= 6)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    number.name.resolve(lang),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  localizedDigits(number.number, lang),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            )
          else ...[
            Text(number.name.resolve(lang), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              localizedDigits(_grouped(number.number), lang),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
          if (number.address != null) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(child: Text(number.address!.resolve(lang), style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
          const SizedBox(height: JSpace.xs),
          Text(number.description.resolve(lang), style: theme.textTheme.bodyMedium),
          if (!v.isVerified) ...[
            const SizedBox(height: JSpace.sm),
            const UnverifiedLabel(),
          ],
          if (sourceUrl != null)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => launchUrl(Uri.parse(sourceUrl), mode: LaunchMode.externalApplication),
              child: Text('${s.sourceLabel}: ${v.sourceName ?? sourceUrl}'),
            ),
          const SizedBox(height: JSpace.xs),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: isNational
                  ? FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white)
                  : null,
              onPressed: () => ref.read(phoneServiceProvider).dial(number.number),
              icon: const Icon(Icons.call),
              label: Text(s.callNumber(number.number)),
            ),
          ),
          if (number.otherNumbers.isNotEmpty) ...[
            const SizedBox(height: JSpace.sm),
            Text(s.otherNumbers, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final other in number.otherNumbers)
                  ActionChip(
                    avatar: const Icon(Icons.call, size: 18),
                    label: Text(localizedDigits(_grouped(other), lang)),
                    onPressed: () => ref.read(phoneServiceProvider).dial(other),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 01320001223 → 01320-001223, 02223355555 → 02-223355555.
String _grouped(String n) {
  if (RegExp(r'^01\d{9}$').hasMatch(n)) return '${n.substring(0, 5)}-${n.substring(5)}';
  if (n.startsWith('02') && n.length > 6) return '02-${n.substring(2)}';
  return n;
}
