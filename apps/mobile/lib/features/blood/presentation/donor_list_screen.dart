import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/features/blood/data/remote_donors.dart';
import 'package:joruri_bd/features/blood/presentation/blood_query_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Step 2: everyone with the needed blood group, with a Call button,
/// filtered by division, district and area.
class DonorListScreen extends ConsumerStatefulWidget {
  const DonorListScreen({super.key});

  @override
  ConsumerState<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends ConsumerState<DonorListScreen> {
  late final TextEditingController _area = TextEditingController(text: ref.read(bloodQueryProvider).areaText);

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final query = ref.watch(bloodQueryProvider);
    final controller = ref.read(bloodQueryProvider.notifier);
    final results = ref.watch(donorResultsProvider);

    final divisionId = query.divisionId;
    final districts = [
      ...(divisionId == null ? BdLocations.districts : BdLocations.districtsOf(divisionId)),
    ]..sort((a, b) => a.name(lang).compareTo(b.name(lang)));

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.donorsTitle(query.needed.label))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in BloodGroup.values)
                  Padding(
                    padding: const EdgeInsets.only(right: JSpace.sm),
                    child: ChoiceChip(
                      label: Text(g.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      selected: g == query.needed,
                      onSelected: (_) => controller.setGroup(g),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: JSpace.md),
          Text(s.filters, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.sm),
          _Picker<String?>(
            label: s.division,
            value: divisionId,
            items: [
              (null, s.allDivisions),
              for (final d in BdLocations.divisions) (d.id, d.name(lang)),
            ],
            onChanged: controller.setDivision,
          ),
          const SizedBox(height: JSpace.sm),
          _Picker<String?>(
            label: s.district,
            value: query.districtId,
            items: [
              (null, s.allDistricts),
              for (final d in districts) (d.id, d.name(lang)),
            ],
            onChanged: controller.setDistrict,
          ),
          const SizedBox(height: JSpace.sm),
          TextField(
            controller: _area,
            onChanged: controller.setArea,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: s.searchArea,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.includeCompatible),
            value: query.includeCompatible,
            onChanged: controller.setIncludeCompatible,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.availableOnly),
            value: query.availableOnly,
            onChanged: controller.setAvailableOnly,
          ),
          const Divider(),
          _LiveListBanner(
            signedIn: ref.watch(signedInProvider),
            liveFailed: ref
                .watch(remoteDonorsProvider(
                  (query.includeCompatible ? query.needed.canReceiveFrom : [query.needed]).map((g) => g.label).join(','),
                ))
                .hasError,
          ),
          results.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(JSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(s.genericError),
            data: (donors) => donors.isEmpty
                ? const _NoDonors()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
                        child: Text(
                          localizedDigits(s.donorsFound(donors.length), lang),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      for (final d in donors) DonorCard(donor: d, compatibleOnly: d.bloodGroup != query.needed),
                    ],
                  ),
          ),
          const SizedBox(height: JSpace.md),
          Text(s.bloodDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Picker<T> extends StatelessWidget {
  const _Picker({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 420,
          items: [
            for (final (v, text) in items) DropdownMenuItem<T>(value: v, child: Text(text)),
          ],
          onChanged: (v) => onChanged(v as T),
        ),
      ),
    );
  }
}

/// One donor: group, name, area, and the number with a big Call button.
class DonorCard extends ConsumerWidget {
  const DonorCard({super.key, required this.donor, this.compatibleOnly = false});

  final Donor donor;
  final bool compatibleOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final district = BdLocations.district(donor.districtId)?.name(lang) ?? donor.districtId;
    final place = donor.area.isEmpty ? district : '${donor.area}, $district';
    final last = donor.lastDonation;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? JColors.nightSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(140)),
        boxShadow: JShadows.soft(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: JColors.blood,
                child: Text(
                  donor.bloodGroup.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(donor.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        if (donor.id == 'me')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.youBadge,
                              style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    Text(place, style: theme.textTheme.bodyMedium),
                    if (last != null)
                      Text(
                        s.lastDonated(localizedDigits(SosMessageBuilder.formatTime(last).substring(0, 10), lang)),
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (donor.verified)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 16, color: JColors.ok),
                              const SizedBox(width: 4),
                              Text(s.verifiedDonor, style: const TextStyle(color: JColors.ok, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        if (!donor.available) Text(s.notAvailableNow, style: const TextStyle(color: JColors.warning)),
                        if (compatibleOnly) Text(s.compatibleBadge, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    if (donor.demo) UnverifiedLabel(text: s.demoDonor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  BdPhone.display(donor.phone),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
                onPressed: () => ref.read(phoneServiceProvider).dial(donor.phone),
                icon: const Icon(Icons.call),
                label: Text(s.callShort),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoDonors extends ConsumerWidget {
  const _NoDonors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.noDonorsTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.xs),
          Text(s.noDonorsBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
            onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            icon: const Icon(Icons.call),
            label: Text(s.call999),
          ),
        ],
      ),
    );
  }
}

/// Tells the person whether they see the live online list, and how to get it.
class _LiveListBanner extends StatelessWidget {
  const _LiveListBanner({required this.signedIn, required this.liveFailed});

  final bool signedIn;

  /// Signed in, but the online list was refused or unreachable (for example
  /// while the server rules are still locked). The bundled list is shown.
  final bool liveFailed;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    if (signedIn) {
      final ok = !liveFailed;
      return Padding(
        padding: const EdgeInsets.only(top: JSpace.xs),
        child: Row(
          children: [
            Icon(ok ? Icons.wifi_tethering : Icons.wifi_tethering_off, size: 18, color: ok ? JColors.ok : JColors.warning),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ok ? s.liveListOn : s.liveListUnavailable,
                style: TextStyle(color: ok ? JColors.ok : JColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: JSpace.sm),
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.liveListTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(s.liveListBodyGoogle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.sm),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/sign-in'),
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(s.signInWithGoogle),
          ),
        ],
      ),
    );
  }
}
