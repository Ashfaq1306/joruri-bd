import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/firebase/firebase_ready.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/presentation/profile_sync_controller.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// "My profile" at the top of Settings: who you are, whether you are in
/// the donor list, and a switch to set your own availability.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final p = ref.watch(profileProvider);

    final decoration = BoxDecoration(
      color: dark ? JColors.nightSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dark ? const Color(0x14FFFFFF) : const Color(0x1A103026)),
      boxShadow: JShadows.soft(context),
    );

    if (p == null) {
      return Container(
        padding: const EdgeInsets.all(JSpace.md),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.noProfileYet, style: theme.textTheme.bodyLarge),
            const SizedBox(height: JSpace.md),
            FilledButton.icon(
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.person_add),
              label: Text(s.saveAccount),
            ),
          ],
        ),
      );
    }

    final district = BdLocations.district(p.districtId)?.name(lang) ?? p.districtId;
    final user = ref.watch(authUserProvider).valueOrNull;
    final sync = ref.watch(profileSyncStatusProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.sm, JSpace.sm),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [Color(0xFFD33A3A), JColors.blood, Color(0xFF8D1414)],
                  ),
                  boxShadow: [BoxShadow(color: Color(0xB3B71C1C), blurRadius: 18, spreadRadius: -8, offset: Offset(0, 8))],
                ),
                child: Text(
                  p.bloodGroup.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(BdPhone.display(p.phone), style: theme.textTheme.bodyMedium),
                    Text(p.area.isEmpty ? district : '${p.area}, $district', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.editProfile,
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: JSpace.sm),
          Row(
            children: [
              Icon(
                p.listedAsDonor ? Icons.verified : Icons.info_outline,
                size: 18,
                color: p.listedAsDonor ? JColors.ok : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                p.listedAsDonor ? s.listedAsDonor : s.notListed,
                style: TextStyle(
                  color: p.listedAsDonor ? JColors.ok : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: JSpace.xs),
          _OnlineStatus(signedIn: user != null, sync: sync),
          if (user == null) ...[
            const SizedBox(height: JSpace.sm),
            FilledButton.icon(
              onPressed: () => context.push('/sign-in'),
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(s.signInWithGoogle),
            ),
          ] else if (!sync.running &&
              (sync.status == SyncStatus.waitingForNetwork ||
                  sync.status == SyncStatus.failed ||
                  sync.status == SyncStatus.notAllowed)) ...[
            const SizedBox(height: JSpace.sm),
            OutlinedButton.icon(
              onPressed: () => ref.read(profileSyncStatusProvider.notifier).sync(),
              icon: const Icon(Icons.refresh),
              label: Text(s.syncRetry),
            ),
          ],
          if (user != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // Signing out never deletes anything online.
                onPressed: () async {
                  await ref.read(googleAuthProvider).signOut();
                  ref.read(profileSyncStatusProvider.notifier).reset();
                },
                child: Text(s.signOut),
              ),
            ),
          if (p.listedAsDonor)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.availableToggle),
              value: p.available,
              onChanged: (v) => ref.read(profileProvider.notifier).setAvailable(v),
            ),
        ],
      ),
    );
  }
}

/// "Saved on this phone" is always true; this line says what happened online.
class _OnlineStatus extends StatelessWidget {
  const _OnlineStatus({required this.signedIn, required this.sync});

  final bool signedIn;
  final ProfileSyncState sync;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final (IconData icon, Color color, String text) = !signedIn
        ? (Icons.cloud_off_outlined, JColors.warning, s.syncSignedOut)
        : sync.running
            ? (Icons.cloud_sync_outlined, JColors.toolkit, s.syncSyncing)
            : switch (sync.status) {
                SyncStatus.synced => (Icons.cloud_done_outlined, JColors.ok, s.syncDone),
                SyncStatus.waitingForNetwork => (Icons.cloud_queue, JColors.warning, s.syncWaiting),
                SyncStatus.notAllowed => (Icons.lock_outline, JColors.warning, s.syncNotAllowed),
                SyncStatus.failed => (Icons.error_outline, JColors.warning, s.syncFailed),
                SyncStatus.offlineOnly => (Icons.cloud_off_outlined, JColors.warning, s.onlineNotReady),
                SyncStatus.signedOut => (Icons.cloud_outlined, JColors.toolkit, s.syncSavedLocal),
              };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
