import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/location_filter.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Pharmacies in your area; 24-hour ones first.
class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  bool _only24h = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final filter = ref.watch(placeFilterProvider);
    final controller = ref.read(placeFilterProvider.notifier);
    final pharmacies = ref.watch(pharmaciesProvider);

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.tilePharmacy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
        children: [
          Text(s.pharmacyHint, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          LocationFilterFields(
            filter: filter,
            onDivision: controller.setDivision,
            onDistrict: controller.setDistrict,
            onArea: controller.setArea,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.only24h),
            value: _only24h,
            onChanged: (v) => setState(() => _only24h = v),
          ),
          pharmacies.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(s.genericError),
            data: (all) {
              final list = all
                  .where((p) => filter.accepts(p.districtId, p.area) && (!_only24h || p.open24h))
                  .toList()
                ..sort((a, b) => (b.open24h ? 1 : 0).compareTo(a.open24h ? 1 : 0));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: JSpace.md),
                      child: Text(s.noPharmacies, style: theme.textTheme.titleMedium),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
                      child: Text(localizedDigits(s.pharmaciesFound(list.length), lang),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    for (final p in list) _PharmacyCard(pharmacy: p),
                  ],
                  FilledButton.icon(
                    onPressed: () => searchInMaps('pharmacy'),
                    icon: const Icon(Icons.map),
                    label: Text(s.searchPharmaciesInMaps),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends ConsumerWidget {
  const _PharmacyCard({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final p = pharmacy;
    final district = BdLocations.district(p.districtId)?.name(lang) ?? p.districtId;
    return PlaceCard(
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: JColors.firstAid, child: Icon(Icons.local_pharmacy, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(p.area.isEmpty ? district : '${p.area}, $district', style: theme.textTheme.bodyMedium),
                if (p.open24h) Tag(icon: Icons.schedule, text: s.open24h, color: JColors.ok),
                if (p.demo) UnverifiedLabel(text: s.demoPlace),
              ],
            ),
          ),
          const SizedBox(width: JSpace.sm),
          FilledButton.icon(
            onPressed: () => ref.read(phoneServiceProvider).dial(p.phone),
            icon: const Icon(Icons.call),
            label: Text(s.callShort),
          ),
        ],
      ),
    );
  }
}
