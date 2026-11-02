import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Road accident mode: six large actions on one screen, no menus.
class AccidentScreen extends ConsumerWidget {
  const AccidentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final phone = ref.read(phoneServiceProvider);
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: GlassAppBar(
        backgroundColor: JColors.amber,
        foregroundColor: JColors.ink,
        title: Text(s.roadAccident, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(JSpace.md),
          children: [
            Container(
              padding: const EdgeInsets.all(JSpace.md),
              decoration: BoxDecoration(
                color: const Color(0x33FFB300),
                borderRadius: BorderRadius.circular(JSize.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.accidentSafetyNote, style: Theme.of(context).textTheme.bodyLarge)),
                ],
              ),
            ),
            const SizedBox(height: JSpace.md),
            BigActionButton(
              icon: Icons.sos,
              label: 'SOS',
              background: JColors.sos,
              onTap: () => context.push('/sos'),
            ),
            gap,
            BigActionButton(
              icon: Icons.emergency,
              label: s.ambulance999,
              background: JColors.ambulance,
              onTap: () => phone.dial(AppConfig.nationalEmergencyNumber),
            ),
            gap,
            BigActionButton(
              icon: Icons.local_police,
              label: s.police999,
              background: JColors.police,
              onTap: () => phone.dial(AppConfig.nationalEmergencyNumber),
            ),
            gap,
            BigActionButton(
              icon: Icons.local_hospital,
              label: s.nearestHospitals,
              background: JColors.hospital,
              onTap: () => context.push('/hospitals'),
            ),
            gap,
            BigActionButton(
              icon: Icons.my_location,
              label: s.myLocation,
              background: JColors.disaster,
              onTap: () => context.push('/location'),
            ),
            gap,
            BigActionButton(
              icon: Icons.call,
              label: s.callMyContact,
              background: JColors.firstAid,
              onTap: () => callPrimaryContact(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
