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
  const HospitalsScreen({super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  final _testQuery = TextEditingController();

  static const _quickTests = ['CBC', 'X-ray', 'ECG', 'Ultrasound', 'Dengue', 'Sugar', 'CT', 'MRI'];

  @override
  void dispose() {
    _testQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final filter = ref.watch(placeFilterProvider);
    final controller = ref.read(placeFilterProvider.notifier);
    final hospitals = ref.watch(hospitalsProvider);

    final filterFields = Padding(
      padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, JSpace.sm),
      child: LocationFilterFields(
        filter: filter,
        onDivision: controller.setDivision,
        onDistrict: controller.setDistrict,
        onArea: controller.setArea,
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
            final inArea = all.where((h) => filter.accepts(h.districtId, h.area)).toList()
              ..sort((a, b) => (b.emergency ? 1 : 0).compareTo(a.emergency ? 1 : 0));
            return TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: JSpace.xl),
                  children: [
                    filterFields,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
                      child: inArea.isEmpty
                          ? _Empty(text: s.noHospitals, mapsQuery: 'hospital', mapsLabel: s.searchHospitalsInMaps)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Count(text: s.hospitalsFound(inArea.length)),
                                for (final h in inArea) HospitalCard(hospital: h),
                                OutlinedButton.icon(
                                  onPressed: () => searchInMaps('hospital'),
                                  icon: const Icon(Icons.map),
                                  label: Text(s.searchHospitalsInMaps),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                _TestSearch(all: all, filter: filter, filterFields: filterFields, controller: _testQuery, quickTests: _quickTests),
              ],
            );
          },
        ),
      ),
    );
  }
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
                        for (final o in offers)
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
                                Text(o.hospital.name, style: theme.textTheme.bodyLarge),
                                Text(_place(o.hospital.area, o.hospital.districtId, lang), style: theme.textTheme.bodyMedium),
                                if (o.hospital.demo) UnverifiedLabel(text: s.demoPlace),
                                const SizedBox(height: JSpace.sm),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => ref.read(phoneServiceProvider).dial(o.hospital.phone),
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
          Text(h.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                child: OutlinedButton.icon(
                  onPressed: () => phone.dial(h.phone),
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
