import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/widgets/logo.dart';
import 'package:joruri_bd/features/announcements/announcements.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/home/presentation/network_pill.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/features/toolkit/presentation/toolkit_controllers.dart';
import 'package:joruri_bd/features/update/update_banner.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// The most important screen: SOS first, then eight actions, then accident mode.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easy = ref.watch(settingsProvider.select((s) => s.easyMode));
    return easy ? const _EasyHome() : const _StandardHome();
  }
}

class _StandardHome extends ConsumerWidget {
  const _StandardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final hasContacts = ref.watch(contactsProvider).isNotEmpty;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.7).toDouble();

    final tiles = <(IconData, String, Color, VoidCallback)>[
      (Icons.bloodtype, s.tileBlood, JColors.blood, () => context.push('/blood')),
      (Icons.emergency, s.tileAmbulance, JColors.ambulance, () => context.push('/numbers/ambulance')),
      (Icons.local_hospital, s.tileHospitals, JColors.hospital, () => context.push('/hospitals')),
      (Icons.local_pharmacy, s.tilePharmacy, JColors.firstAid, () => context.push('/pharmacy')),
      (Icons.local_police, s.tilePolice, JColors.police, () => context.push('/numbers/police')),
      (Icons.local_fire_department, s.tileFire, JColors.fire, () => context.push('/numbers/fire')),
      (Icons.flood, s.tileDisaster, JColors.disaster, () => context.go('/guides?tab=1')),
      (Icons.medical_services, s.tileFirstAid, JColors.sos, () => context.go('/guides?tab=0')),
      (Icons.flashlight_on, s.tileToolkit, JColors.toolkit, () => context.push('/toolkit')),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.lg),
          children: [
            const _SosPanel(diameter: JSize.sosButton),
            const SizedBox(height: JSpace.md),
            const UpdateBanner(),
            const AnnouncementsList(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 108 * textScale,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, i) {
                final (icon, label, color, onTap) = tiles[i];
                return ActionTile(icon: icon, label: label, color: color, onTap: onTap, vertical: true);
              },
            ),
            const SizedBox(height: JSpace.md),
            const _AccidentBar(),
            if (!hasContacts) ...[
              const SizedBox(height: JSpace.md),
              const _AddContactCard(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Easy Mode: one column of very large buttons, nothing else.
class _EasyHome extends ConsumerWidget {
  const _EasyHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    const gap = SizedBox(height: 12);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(JSpace.md),
          children: [
            const _SosPanel(diameter: JSize.sosButtonEasy),
            const SizedBox(height: JSpace.md),
            const UpdateBanner(),
            const AnnouncementsList(),
            BigActionButton(
              icon: Icons.call,
              label: s.callMyContact,
              background: JColors.firstAid,
              onTap: () => callPrimaryContact(context, ref),
            ),
            gap,
            BigActionButton(
              icon: Icons.emergency,
              label: s.call999,
              background: JColors.police,
              onTap: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            ),
            gap,
            BigActionButton(
              icon: Icons.directions_car,
              label: s.roadAccident,
              background: JColors.amber,
              foreground: JColors.ink,
              onTap: () => context.push('/accident'),
            ),
            gap,
            BigActionButton(
              icon: Icons.medical_services,
              label: s.tileFirstAid,
              background: JColors.hospital,
              onTap: () => context.go('/guides?tab=0'),
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
              icon: Icons.flashlight_on,
              label: s.flashlight,
              background: JColors.toolkit,
              onTap: () => ref.read(torchProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green panel with the red SOS disc: the Bangladesh flag, and the one bold
/// element on the screen.
class _SosPanel extends StatelessWidget {
  const _SosPanel({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, JSpace.md, 18, JSpace.lg),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: RadialGradient(
          center: const Alignment(-1, -1),
          radius: 1.6,
          colors: dark
              ? const [Color(0xFF0A6F52), JColors.flagGreenDark, Color(0xFF00301F)]
              : const [Color(0xFF0C8D68), JColors.flagGreen, Color(0xFF004A36)],
          stops: const [0, 0.48, 1],
        ),
        boxShadow: const [BoxShadow(color: Color(0xA6005036), blurRadius: 44, spreadRadius: -20, offset: Offset(0, 22))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const LogoTile(size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      s.brandLine,
                      style: const TextStyle(color: Color(0xD1FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w500, letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
              const NetworkPill(onDark: true),
            ],
          ),
          const SizedBox(height: 20),
          SosButton(
            label: 'SOS',
            hint: s.sosHint,
            diameter: diameter,
            onPressed: () => context.push('/sos'),
          ),
          const SizedBox(height: JSpace.md),
          Text(
            s.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xF2FFFFFF), fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AccidentBar extends StatelessWidget {
  const _AccidentBar();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Semantics(
      button: true,
      label: s.roadAccident,
      excludeSemantics: true,
      child: Material(
        color: JColors.amber,
        borderRadius: BorderRadius.circular(JSize.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(JSize.radius),
          onTap: () => context.push('/accident'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: JSpace.md, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: JColors.ink, size: 30),
                const SizedBox(width: JSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.roadAccident,
                        style: const TextStyle(color: JColors.ink, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(s.roadAccidentHint, style: const TextStyle(color: JColors.ink, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: JColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddContactCard extends StatelessWidget {
  const _AddContactCard();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(JSize.radius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.noContactsTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: JSpace.xs),
          Text(s.noContactsBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.md),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/contacts'),
            icon: const Icon(Icons.person_add),
            label: Text(s.addContact),
          ),
        ],
      ),
    );
  }
}
