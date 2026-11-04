import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Hospitals in your area, and "Tests & prices": which hospital does a test
/// and what it costs, cheapest first.
class HospitalsScreen extends ConsumerStatefulWidget {
  const HospitalsScreen({super.key, this.bloodBanksOnly = false});

  /// Opened from the Blood screen: start with blood banks selected.
  final bool bloodBanksOnly;

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  final _testQuery = TextEditingController();
  late _Kind _kind = widget.bloodBanksOnly ? _Kind.bloodBank : _Kind.all;

  static const _quickTests = ['CBC', 'X-ray', 'ECG', 'Ultrasound', 'Sugar', 'Creatinine', 'CT', 'MRI'];

  /// Cards drawn at most; the rest is reached by narrowing the search.
  static const _maxShown = 400;

  @override
  void dispose() {
    _testQuery.dispose();
    super.dispose();
  }

  bool _accepts(Hospital h, PlaceFilter filter, String text) {
    // District only: the typed text is matched against name/area/address below.
    // (accepts(h.districtId, '') also matched the text against '', so any
    // search found no hospital at all.)
    if (!filter.acceptsDistrict(h.districtId)) return false;
    switch (_kind) {
      case _Kind.all:
        break;
      case _Kind.government:
        if (!h.government) return false;
      case _Kind.private:
        if (h.government) return false;
      case _Kind.emergency:
        if (!h.emergency) return false;
      case _Kind.bloodBank:
        if (!h.bloodBank) return false;
    }
    return text.isEmpty || h.searchText.contains(text);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filter = ref.watch(placeFilterProvider);
    final controller = ref.read(placeFilterProvider.notifier);
    final hospitals = ref.watch(hospitalsProvider);

    Widget filterFields({bool nameSearch = false}) => Padding(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, JSpace.sm),
          child: LocationFilterFields(
            filter: filter,
            onDivision: controller.setDivision,
            onDistrict: controller.setDistrict,
            onArea: controller.setArea,
            searchLabel: s.searchNameOrArea,
          ),
        );

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
      child: Row(
        children: [
          for (final (k, label) in [
            (_Kind.all, s.allDistricts.split(' ').first),
            (_Kind.government, s.filterGovernment),
            (_Kind.private, s.filterPrivate),
            (_Kind.emergency, s.serviceEmergency),
            (_Kind.bloodBank, s.serviceBloodBank),
          ])
            Padding(
              padding: const EdgeInsets.only(right: JSpace.sm),
              child: ChoiceChip(label: Text(label), selected: _kind == k, onSelected: (_) => setState(() => _kind = k)),
            ),
        ],
      ),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GlassAppBar(
          title: Text(s.tileHospitals),
          bottom: TabBar(tabs: [Tab(text: s.tabHospitalList), Tab(text: s.tabTestsPrices)]),
        ),
        body: hospitals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(s.genericError)),
          data: (all) {
            final text = filter.areaText.trim().toLowerCase();
            final inArea = all.where((h) => _accepts(h, filter, text)).toList()..sort(_byImportance);
            final shown = inArea.length > _maxShown ? inArea.sublist(0, _maxShown) : inArea;
            // header, chips, count, cards…, footer
            final header = <Widget>[
              filterFields(nameSearch: true),
              chips,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                child: inArea.isEmpty
                    ? _Empty(text: s.noHospitals, mapsQuery: 'hospital', mapsLabel: s.searchHospitalsInMaps)
                    : _Count(text: s.hospitalsFound(inArea.length)),
              ),
            ];
            final footer = <Widget>[
              if (shown.length < inArea.length)
                Padding(
                  padding: const EdgeInsets.all(JSpace.md),
                  child: Text(
                    localizedDigits(s.showingFirst(shown.length, inArea.length), s.languageCode),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (inArea.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                  child: OutlinedButton.icon(
                    onPressed: () => searchInMaps('hospital'),
                    icon: const Icon(Icons.map),
                    label: Text(s.searchHospitalsInMaps),
                  ),
                ),
            ];
            return TabBarView(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: JSpace.xl),
                  itemCount: header.length + shown.length + footer.length,
                  itemBuilder: (context, i) {
                    if (i < header.length) return header[i];
                    i -= header.length;
                    if (i < shown.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                        child: HospitalCard(hospital: shown[i]),
                      );
                    }
                    return footer[i - shown.length];
                  },
                ),
                _TestSearch(
                    all: all, filter: filter, filterFields: filterFields(), controller: _testQuery, quickTests: _quickTests),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _Kind { all, government, private, emergency, bloodBank }

/// Emergency departments first, then bigger government hospitals, then by name.
int _byImportance(Hospital a, Hospital b) {
  final e = (b.emergency ? 1 : 0).compareTo(a.emergency ? 1 : 0);
  if (e != 0) return e;
  final r = _rank(a).compareTo(_rank(b));
  if (r != 0) return r;
  return a.name.compareTo(b.name);
}

int _rank(Hospital h) {
  final k = h.kind.toLowerCase();
  if (k.contains('medical college') || k.contains('postgraduate') || k.contains('university')) return 0;
  if (k.contains('district') || k.contains('general hospital') || k.contains('specialized')) return 1;
  if (h.government) return 2;
  if (k.contains('blood bank')) return 4;
  return 3;
}

class _TestSearch extends ConsumerStatefulWidget {
  const _TestSearch({
    required this.all,
    required this.filter,
    required this.filterFields,
    required this.controller,
    required this.quickTests,
  });

  final List<Hospital> all;
  final PlaceFilter filter;
  final Widget filterFields;
  final TextEditingController controller;
  final List<String> quickTests;

  @override
  ConsumerState<_TestSearch> createState() => _TestSearchState();
}

class _TestSearchState extends ConsumerState<_TestSearch> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final query = widget.controller.text;
    final offers = query.trim().isEmpty ? const <TestOffer>[] : findTest(widget.all, query, widget.filter);

    return ListView(
      padding: const EdgeInsets.only(bottom: JSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.testSearchHint, style: theme.textTheme.bodyLarge),
              const SizedBox(height: JSpace.sm),
              TextField(
                controller: widget.controller,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: s.searchTest,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: JSpace.sm),
              Wrap(
                spacing: JSpace.sm,
                runSpacing: JSpace.xs,
                children: [
                  for (final t in widget.quickTests)
                    ActionChip(
                      label: Text(t),
                      onPressed: () => setState(() => widget.controller.text = t),
                    ),
                ],
              ),
            ],
          ),
        ),
        widget.filterFields,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
          child: query.trim().isEmpty
              ? const SizedBox.shrink()
              : offers.isEmpty
                  ? _Empty(text: s.noTestResults)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Count(text: s.testResults(offers.length)),
                        if (offers.length > 150)
                          Padding(
                            padding: const EdgeInsets.only(bottom: JSpace.sm),
                            child: Text(localizedDigits(s.showingFirst(150, offers.length), lang)),
                          ),
                        for (final o in offers.take(150))
                          PlaceCard(
                            onTap: () => context.push('/hospital/${o.hospital.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(o.test.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    ),
                                    _Price(price: o.test.priceBdt, lang: lang),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(o.hospital.displayName(lang), style: theme.textTheme.bodyLarge),
                                Text(_place(o.hospital.area, o.hospital.districtId, lang), style: theme.textTheme.bodyMedium),
                                if (o.hospital.demo) UnverifiedLabel(text: s.demoPlace),
                                const SizedBox(height: JSpace.sm),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonalIcon(
                                    onPressed: o.hospital.allPhones.isEmpty
                                        ? null
                                        : () => ref.read(phoneServiceProvider).dial(o.hospital.allPhones.first),
                                    icon: const Icon(Icons.call),
                                    label: Text(s.callShort),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}

String _place(String area, String districtId, String lang) {
  final district = BdLocations.district(districtId)?.name(lang) ?? districtId;
  return area.isEmpty ? district : '$area, $district';
}

class _Price extends StatelessWidget {
  const _Price({required this.price, required this.lang});

  final int? price;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = price;
    if (p == null) return Text(s.priceUnknown, style: Theme.of(context).textTheme.bodyMedium);
    return Text(
      s.taka(localizedDigits('$p', lang)),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
        child: Text(
          localizedDigits(text, context.s.languageCode),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.mapsQuery, this.mapsLabel});

  final String text;
  final String? mapsQuery;
  final String? mapsLabel;

  @override
  Widget build(BuildContext context) {
    final q = mapsQuery;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          if (q != null) ...[
            const SizedBox(height: JSpace.md),
            FilledButton.icon(onPressed: () => searchInMaps(q), icon: const Icon(Icons.map), label: Text(mapsLabel ?? '')),
          ],
        ],
      ),
    );
  }
}

/// One hospital in the list: services at a glance, call buttons, details.
class HospitalCard extends ConsumerWidget {
  const HospitalCard({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final h = hospital;
    final phone = ref.read(phoneServiceProvider);
    final emergencyPhone = h.emergencyPhone;

    return PlaceCard(
      onTap: () => context.push('/hospital/${h.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(h.displayName(lang), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (h.kind.isNotEmpty)
            Text(h.displayKind(lang), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          Text(_place(h.area, h.districtId, lang), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (h.emergency) Tag(icon: Icons.emergency, text: s.serviceEmergency, color: JColors.sos),
              if (h.open24h) Tag(icon: Icons.schedule, text: s.open24h, color: JColors.ok),
              if (h.bloodBank) Tag(icon: Icons.bloodtype, text: s.serviceBloodBank),
              if (h.ambulance) Tag(icon: Icons.airport_shuttle, text: s.tileAmbulance),
              if (h.icu) Tag(icon: Icons.monitor_heart, text: s.serviceIcu),
              if (h.government) Tag(icon: Icons.account_balance, text: s.filterGovernment),
              if (h.beds != null && h.beds! > 0) Tag(icon: Icons.bed, text: localizedDigits(s.beds(h.beds!), lang)),
              if (h.tests.isNotEmpty)
                Tag(icon: Icons.science, text: '${s.testsAndPrices}: ${localizedDigits('${h.tests.length}', lang)}'),
            ],
          ),
          if (h.demo) UnverifiedLabel(text: s.demoPlace),
          const SizedBox(height: JSpace.sm),
          Row(
            children: [
              if (emergencyPhone != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
                    onPressed: () => phone.dial(emergencyPhone),
                    icon: const Icon(Icons.call),
                    label: Text(s.emergencyLine),
                  ),
                ),
                const SizedBox(width: JSpace.sm),
              ],
              Expanded(
                child: h.allPhones.isEmpty
                    ? OutlinedButton.icon(
                        onPressed: () => openPlaceInMaps(h),
                        icon: const Icon(Icons.directions),
                        label: Text(s.directionsLabel),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => phone.dial(h.allPhones.first),
                        icon: const Icon(Icons.call),
                        label: Text(s.callShort),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Exact spot when the map position is known; otherwise a name search.
Future<void> openPlaceInMaps(Hospital h) {
  final lat = h.latitude, lng = h.longitude;
  if (lat != null && lng != null && lat != 0 && lng != 0) {
    return searchInMaps('$lat,$lng');
  }
  return searchInMaps('${h.name} ${BdLocations.district(h.districtId)?.name('en') ?? ''}');
}
