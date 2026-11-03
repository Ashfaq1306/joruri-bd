import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/features/hospitals/presentation/hospitals_screen.dart';
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
      appBar: GlassAppBar(title: Text(h.displayName(lang))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
        children: [
          if (lang == 'bn' && h.nameBn.isNotEmpty && h.name != h.nameBn)
            Text(h.name, style: theme.textTheme.bodyMedium)
          else if (lang != 'bn' && h.nameBn.isNotEmpty)
            Text(h.nameBn, style: theme.textTheme.bodyMedium),
          if (h.kind.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  h.displayKind(lang),
                  if (h.beds != null && h.beds! > 0) localizedDigits(s.beds(h.beds!), lang),
                ].join(' · '),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            [
              if (h.address.isNotEmpty) h.address,
              if (h.area.isNotEmpty && !h.address.toLowerCase().contains(h.area.toLowerCase())) h.area,
              district,
            ].join(', '),
            style: theme.textTheme.bodyLarge,
          ),
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
          if (h.allPhones.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: JSpace.sm),
              child: Text(s.noPhoneListed, style: theme.textTheme.bodyMedium),
            ),
          for (final number in h.allPhones) ...[
            OutlinedButton.icon(
              onPressed: () => phone.dial(number),
              icon: const Icon(Icons.call),
              label: Text('${s.callShort}: ${localizedDigits(number, lang)}'),
            ),
            const SizedBox(height: JSpace.sm),
          ],
          OutlinedButton.icon(
            onPressed: () => openPlaceInMaps(h),
            icon: const Icon(Icons.directions),
            label: Text(s.openInMaps),
          ),
          if (h.email.isNotEmpty || h.website.isNotEmpty) ...[
            const SizedBox(height: JSpace.sm),
            if (h.email.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: Text(h.email),
                subtitle: Text(s.emailLabel),
                onTap: () => launchUrl(Uri(scheme: 'mailto', path: h.email)),
              ),
            if (h.website.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(h.website),
                subtitle: Text(s.websiteLabel),
                onTap: () => launchUrl(
                  Uri.parse(h.website.startsWith('http') ? h.website : 'https://${h.website}'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
          if (h.source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: JSpace.sm),
              child: Text('${s.sourceLabel}: ${h.source}', style: theme.textTheme.bodySmall),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: theme.textTheme.bodyLarge),
                          if (t.note.isNotEmpty) Text(t.note, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
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
