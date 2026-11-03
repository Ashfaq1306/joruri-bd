import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/core/widgets/location_filter.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/pharmacy/presentation/medicine_prices_tab.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Licensed pharmacies of a district (DGDA register plus the team's own
/// entries), and "Medicine prices": DGDA-approved price of every brand.
class PharmacyScreen extends ConsumerStatefulWidget {
  const PharmacyScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen> {
  bool _only24h = false;
  bool _onlyWithPhone = false;

  /// Cards drawn at most; the rest is reached by narrowing the search.
  static const _maxShown = 400;

  @override
  void initState() {
    super.initState();
    // First visit: start in the district from the user's profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(placeFilterProvider).districtId != null) return;
      final home = ref.read(profileProvider)?.districtId;
      if (home != null && BdLocations.district(home) != null) ref.read(placeFilterProvider.notifier).setDistrict(home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filter = ref.watch(placeFilterProvider);
    final controller = ref.read(placeFilterProvider.notifier);
    final district = filter.districtId;
    final today = DateTime.now();

    final header = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, 0),
        child: LocationFilterFields(
          filter: filter,
          onDivision: controller.setDivision,
          onDistrict: controller.setDistrict,
          onArea: controller.setArea,
          searchLabel: s.searchPharmacyHint,
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: JSpace.md, vertical: JSpace.sm),
        child: Row(
          children: [
            FilterChip(
              label: Text(s.onlyWithPhone),
              selected: _onlyWithPhone,
              onSelected: (v) => setState(() => _onlyWithPhone = v),
            ),
            const SizedBox(width: JSpace.sm),
            FilterChip(label: Text(s.only24h), selected: _only24h, onSelected: (v) => setState(() => _only24h = v)),
          ],
        ),
      ),
    ];

    Widget list;
    if (district == null) {
      list = ListView(
        padding: const EdgeInsets.only(bottom: JSpace.xl),
        children: [
          ...header,
          Padding(
            padding: const EdgeInsets.all(JSpace.md),
            child: Text(s.chooseDistrictForPharmacies, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      );
    } else {
      list = ref.watch(districtPharmaciesProvider(district)).when(
            loading: () => ListView(children: [...header, const Center(child: CircularProgressIndicator())]),
            error: (_, __) => ListView(children: [...header, Center(child: Text(s.genericError))]),
            data: (all) {
              final text = filter.areaText.trim().toLowerCase();
              final found = all
                  .where((p) =>
                      (text.isEmpty || p.searchText.contains(text)) &&
                      (!_only24h || p.open24h) &&
                      (!_onlyWithPhone || p.hasPhone))
                  .toList()
                ..sort((a, b) => _byUsefulness(a, b, today));
              final shown = found.length > _maxShown ? found.sublist(0, _maxShown) : found;
              final top = <Widget>[
                ...header,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                  child: found.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: JSpace.md),
                          child: Text(s.noPharmacies, style: Theme.of(context).textTheme.titleMedium),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
                          child: Text(
                            localizedDigits(s.pharmaciesFound(found.length), s.languageCode),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
              ];
              final bottom = <Widget>[
                if (shown.length < found.length)
                  Padding(
                    padding: const EdgeInsets.all(JSpace.md),
                    child: Text(localizedDigits(s.showingFirst(shown.length, found.length), s.languageCode)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                  child: OutlinedButton.icon(
                    onPressed: () => searchInMaps('pharmacy'),
                    icon: const Icon(Icons.map),
                    label: Text(s.searchPharmaciesInMaps),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(JSpace.md),
                  child: Text(s.pharmacySourceNote, style: Theme.of(context).textTheme.bodySmall),
                ),
              ];
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: JSpace.xl),
                itemCount: top.length + shown.length + bottom.length,
                itemBuilder: (context, i) {
                  if (i < top.length) return top[i];
                  i -= top.length;
                  if (i < shown.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                      child: _PharmacyCard(pharmacy: shown[i], today: today),
                    );
                  }
                  return bottom[i - shown.length];
                },
              );
            },
          );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab == 1 ? 1 : 0,
      child: Scaffold(
        appBar: GlassAppBar(
          title: Text(s.tilePharmacy),
          bottom: TabBar(tabs: [Tab(text: s.tabPharmacies), Tab(text: s.tabMedicinePrices)]),
        ),
        body: TabBarView(children: [list, const MedicinePricesTab()]),
      ),
    );
  }
}

/// The team's 24-hour / checked shops first, then shops with a phone number,
/// then shops whose licence is still valid, then by name.
int _byUsefulness(Pharmacy a, Pharmacy b, DateTime today) {
  int score(Pharmacy p) =>
      (p.open24h ? 8 : 0) + (p.verified ? 4 : 0) + (p.hasPhone ? 2 : 0) + (p.licenceValidOn(today) == false ? 0 : 1);
  final c = score(b).compareTo(score(a));
  return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

class _PharmacyCard extends ConsumerWidget {
  const _PharmacyCard({required this.pharmacy, required this.today});

  final Pharmacy pharmacy;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final p = pharmacy;
    final district = BdLocations.district(p.districtId)?.name(lang) ?? p.districtId;
    final place = p.address.isNotEmpty ? p.address : (p.area.isEmpty ? district : '${p.area}, $district');
    final until = p.licenceValidUpto;
    final valid = p.licenceValidOn(today);
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
                Text(place, style: theme.textTheme.bodyMedium),
                if (p.area.isNotEmpty && p.address.isNotEmpty && !p.address.toLowerCase().contains(p.area.toLowerCase()))
                  Text('${p.area}, $district', style: theme.textTheme.bodySmall),
                if (p.hasPhone) Text(localizedDigits(p.phone, lang), style: theme.textTheme.bodyMedium),
                if (p.open24h) Tag(icon: Icons.schedule, text: s.open24h, color: JColors.ok),
                if (until != null)
                  Tag(
                    icon: valid == true ? Icons.verified_outlined : Icons.info_outline,
                    text: localizedDigits(
                        valid == true ? s.licenceValidUntil(_date(until)) : s.licenceExpired(_date(until)), lang),
                    color: valid == true ? JColors.ok : null,
                  ),
                if (p.demo) UnverifiedLabel(text: s.demoPlace),
              ],
            ),
          ),
          const SizedBox(width: JSpace.sm),
          if (p.hasPhone)
            FilledButton.icon(
              onPressed: () => ref.read(phoneServiceProvider).dial(p.phone),
              icon: const Icon(Icons.call),
              label: Text(s.callShort),
            )
          else
            OutlinedButton.icon(
              onPressed: () => searchInMaps([p.name, p.address, if (p.area.isNotEmpty) p.area, district].join(', ')),
              icon: const Icon(Icons.directions),
              label: Text(s.pharmacyDirections),
            ),
        ],
      ),
    );
  }
}
