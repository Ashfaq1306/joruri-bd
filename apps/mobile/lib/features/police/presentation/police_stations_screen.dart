import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/core/widgets/location_filter.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Every police station (thana) with the officer in charge's number.
/// Starts in the district of the user's profile; typing a thana name
/// searches the whole country when no district is chosen.
class PoliceStationsScreen extends ConsumerStatefulWidget {
  const PoliceStationsScreen({super.key});

  @override
  ConsumerState<PoliceStationsScreen> createState() => _PoliceStationsScreenState();
}

class _PoliceStationsScreenState extends ConsumerState<PoliceStationsScreen> {
  /// Own search text: a thana name must not carry over into the Hospitals
  /// and Pharmacy screens (they share the district choice, not the text).
  String _text = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(placeFilterProvider).districtId != null) return;
      final home = ref.read(profileProvider)?.districtId;
      if (home != null && BdLocations.district(home) != null) ref.read(placeFilterProvider.notifier).setDistrict(home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final filter = ref.watch(placeFilterProvider);
    final controller = ref.read(placeFilterProvider.notifier);
    final text = _text.trim();

    final header = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, 0),
        child: _Call999Banner(text: s.policeNumberTip),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, 0),
        child: LocationFilterFields(
          filter: filter.copyWith(areaText: _text),
          onDivision: controller.setDivision,
          onDistrict: controller.setDistrict,
          onArea: (v) => setState(() => _text = v),
          searchLabel: s.searchPoliceHint,
        ),
      ),
    ];

    // The search fields stay above the list and are never rebuilt in a new
    // place: otherwise the first typed letter switches the list widget, the
    // text field loses focus and the keyboard closes after one letter.
    final results = ref.watch(policeStationsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(s.genericError)),
          data: (all) {
            final district = filter.districtId;
            final division = filter.divisionId;
            if (district == null && text.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(JSpace.md),
                  child: Text(s.chooseDistrictForPolice, style: theme.textTheme.titleMedium),
                ),
              ]);
            }
            var found = searchStations(all, districtId: district, text: text);
            if (district == null && division != null) {
              found = [for (final st in found) if (BdLocations.district(st.districtId)?.divisionId == division) st];
            }
            final top = <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.sm),
                child: Text(
                  found.isEmpty ? s.noPoliceStations : localizedDigits(s.policeStationsFound(found.length), s.languageCode),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ];
            final bottom = <Widget>[
              Padding(
                padding: const EdgeInsets.all(JSpace.md),
                child: Text(s.policeSourceNote, style: theme.textTheme.bodySmall),
              ),
            ];
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: JSpace.xl),
              itemCount: top.length + found.length + bottom.length,
              itemBuilder: (context, i) {
                if (i < top.length) return top[i];
                i -= top.length;
                if (i < found.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                    child: StationCard(station: found[i], showDistrict: district == null),
                  );
                }
                return bottom[i - found.length];
              },
            );
          },
        );

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.policeStations)),
      body: Column(children: [...header, Expanded(child: results)]),
    );
  }
}

class _Call999Banner extends ConsumerWidget {
  const _Call999Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: JColors.sos.withAlpha(24), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: JSpace.sm),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
            onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            icon: const Icon(Icons.call),
            label: Text(localizedDigits('999', context.s.languageCode)),
          ),
        ],
      ),
    );
  }
}

/// One police (or fire) station: name, unit, district, the OC's number with a
/// call button, other numbers, e-mail and directions.
class StationCard extends ConsumerWidget {
  const StationCard({super.key, required this.station, this.showDistrict = false});

  final Station station;
  final bool showDistrict;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final st = station;
    final district = BdLocations.district(st.districtId)?.name(lang) ?? st.districtId;
    final unit = st.displayUnit(lang);
    final where = [if (unit.isNotEmpty) unit, if (showDistrict || unit.isEmpty) district].join(' · ');
    final phone = ref.read(phoneServiceProvider);
    return PlaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: st.service == StationService.fire ? JColors.fire : JColors.police,
                child: Icon(st.service == StationService.fire ? Icons.local_fire_department : Icons.local_police,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(st.displayName(lang), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (lang == 'bn' && st.nameBn.isNotEmpty) Text(st.name, style: theme.textTheme.bodySmall),
                    if (where.isNotEmpty) Text(where, style: theme.textTheme.bodyMedium),
                    if (st.address.isNotEmpty) Text(st.address, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (st.phone.isNotEmpty) ...[
            const SizedBox(height: JSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.service == StationService.police ? s.officerInCharge : st.displayName(lang),
                          style: theme.textTheme.bodySmall),
                      Text(localizedDigits(BdPhone.display(st.phone), lang),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => phone.dial(st.phone),
                  icon: const Icon(Icons.call),
                  label: Text(s.callShort),
                ),
              ],
            ),
          ],
          for (final other in st.otherPhones.where((p) => p != st.phone))
            Row(
              children: [
                Expanded(child: Text(localizedDigits(BdPhone.display(other), lang), style: theme.textTheme.bodyLarge)),
                TextButton.icon(onPressed: () => phone.dial(other), icon: const Icon(Icons.call), label: Text(s.callShort)),
              ],
            ),
          Wrap(
            spacing: JSpace.sm,
            children: [
              if (st.open24h) Tag(icon: Icons.schedule, text: s.open24h, color: JColors.ok),
              if (st.email.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => launchUrl(Uri(scheme: 'mailto', path: st.email)),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(st.email),
                ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => st.latitude != null && st.longitude != null
                    ? launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${st.latitude},${st.longitude}'),
                        mode: LaunchMode.externalApplication)
                    : searchInMaps([st.name, if (st.address.isNotEmpty) st.address, BdLocations.district(st.districtId)?.en ?? ''].join(', ')),
                icon: const Icon(Icons.directions, size: 18),
                label: Text(s.directionsLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
