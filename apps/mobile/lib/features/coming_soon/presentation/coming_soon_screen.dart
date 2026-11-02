import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Honest placeholder for features from later phases, always with
/// something useful the person can do right now.
class ComingSoonScreen extends ConsumerWidget {
  const ComingSoonScreen({super.key, required this.feature});

  /// 'blood' or 'hospitals'.
  final String feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final hospitals = feature == 'hospitals';

    return Scaffold(
      appBar: GlassAppBar(title: Text(hospitals ? s.tileHospitals : s.tileBlood)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.lg),
        children: [
          Icon(
            hospitals ? Icons.local_hospital : Icons.bloodtype,
            size: 64,
            color: hospitals ? JColors.hospital : JColors.blood,
          ),
          const SizedBox(height: JSpace.md),
          Text(
            hospitals ? s.hospitalsComingSoonTitle : s.bloodComingSoonTitle,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: JSpace.sm),
          Text(hospitals ? s.hospitalsComingSoonBody : s.bloodComingSoonBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.lg),
          if (hospitals) ...[
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://www.google.com/maps/search/?api=1&query=hospital'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.map),
              label: Text(s.searchHospitalsInMaps),
            ),
            const SizedBox(height: JSpace.sm),
          ],
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
