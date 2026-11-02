import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// One hospital: calls, services, and its full list of tests with prices.
class HospitalDetailScreen extends ConsumerStatefulWidget {
  const HospitalDetailScreen({super.key, required this.hospitalId});

  final String hospitalId;

  @override
  ConsumerState<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends ConsumerState<HospitalDetailScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    Hospital? hospital;
    final all = ref.watch(hospitalsProvider);
    for (final h in all.valueOrNull ?? const <Hospital>[]) {
      if (h.id == widget.hospitalId) hospital = h;
    }
    final h = hospital;
    if (h == null) {
      // Still reading the list: a spinner, not a false "something went wrong".
      return Scaffold(
        appBar: const GlassAppBar(),
        body: Center(child: all.isLoading ? const CircularProgressIndicator() : Text(s.genericError)),
      );
    }
    final phone = ref.read(phoneServiceProvider);
    final emergencyPhone = h.emergencyPhone;
    final district = BdLocations.district(h.districtId)?.name(lang) ?? h.districtId;
    final tests = _query.trim().isEmpty ? h.tests : h.tests.where((t) => t.matches(_query)).toList();
    final checked = h.pricesCheckedOn;

    return Scaffold(
      appBar: GlassAppBar(title: Text(h.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
        children: [
          Text(h.address.isEmpty ? district : '${h.address}, $district', style: theme.textTheme.bodyLarge),
          if (h.demo) UnverifiedLabel(text: s.demoPlace),
          const SizedBox(height: JSpace.sm),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (h.emergency) Tag(icon: Icons.emergency, text: s.serviceEmergency, color: JColors.sos),
              if (h.open24h) Tag(icon: Icons.schedule, text: s.open24h, color: JColors.ok),
              if (h.bloodBank) Tag(icon: Icons.bloodtype, text: s.serviceBloodBank),
              if (h.ambulance) Tag(icon: Icons.airport_shuttle, text: s.tileAmbulance),
              if (h.icu) Tag(icon: Icons.monitor_heart, text: s.serviceIcu),
            ],
          ),
          const SizedBox(height: JSpace.md),
          if (emergencyPhone != null) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
              onPressed: () => phone.dial(emergencyPhone),
              icon: const Icon(Icons.call),
              label: Text('${s.emergencyLine}: $emergencyPhone'),
            ),
            const SizedBox(height: JSpace.sm),
          ],
          OutlinedButton.icon(
            onPressed: () => phone.dial(h.phone),
            icon: const Icon(Icons.call),
            label: Text('${s.callShort}: ${h.phone}'),
          ),
          const SizedBox(height: JSpace.sm),
          OutlinedButton.icon(
            onPressed: () => searchInMaps('${h.name} $district'),
            icon: const Icon(Icons.directions),
            label: Text(s.openInMaps),
          ),
          if (h.tests.isNotEmpty) ...[
            const SizedBox(height: JSpace.lg),
            Text(s.testsAndPrices, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (checked != null)
              Text(s.pricesChecked(localizedDigits(checked.split('-').reversed.join('/'), lang)),
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: JSpace.sm),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                labelText: s.searchTestInHospital,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: JSpace.sm),
            for (final t in tests)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
                child: Row(
                  children: [
                    Expanded(child: Text(t.name, style: theme.textTheme.bodyLarge)),
                    Text(
                      t.priceBdt == null ? s.priceUnknown : s.taka(localizedDigits('${t.priceBdt}', lang)),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
