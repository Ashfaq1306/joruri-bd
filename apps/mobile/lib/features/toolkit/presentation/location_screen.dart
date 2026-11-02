import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/platform/location_service.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// GPS coordinates with copy, share, open in Maps and text-to-contacts.
/// Coordinates work offline; only opening Maps needs internet.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  LocationResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final location = _result?.location;
    final issue = _result?.issue;
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.myLocation)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          Text(s.locationReason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.md),
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: JSpace.sm),
            Text(s.sosLocating),
          ],
          if (!_loading && location != null) ...[
            _Coordinate(label: s.latitude, value: location.latitude.toStringAsFixed(5)),
            _Coordinate(label: s.longitude, value: location.longitude.toStringAsFixed(5)),
            if (location.accuracyMeters != null)
              Text(s.accuracyMeters(location.accuracyMeters!.round()), style: theme.textTheme.bodyLarge),
            Text(s.locationTime(SosMessageBuilder.formatTime(location.fixTime)), style: theme.textTheme.bodyMedium),
            const SizedBox(height: JSpace.lg),
            FilledButton.icon(
              onPressed: () => Share.share(s.myLocationMessage(location.mapLink)),
              icon: const Icon(Icons.share),
              label: Text(s.share),
            ),
            if (contacts.isNotEmpty) ...[
              const SizedBox(height: JSpace.sm),
              OutlinedButton.icon(
                onPressed: () => ref.read(smsServiceProvider).compose(
                      contacts.map((c) => c.phone).toList(),
                      s.myLocationMessage(location.mapLink),
                    ),
                icon: const Icon(Icons.sms),
                label: Text(s.textMyContacts),
              ),
            ],
            const SizedBox(height: JSpace.sm),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${location.coordinates}\n${location.mapLink}'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.copied)));
              },
              icon: const Icon(Icons.copy),
              label: Text(s.copyCoordinates),
            ),
            const SizedBox(height: JSpace.sm),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(location.mapLink), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.map),
              label: Text(s.openInMaps),
            ),
          ],
          if (!_loading && location == null) ...[
            Text(
              switch (issue) {
                LocationIssue.serviceOff => s.sosLocationServiceOff,
                LocationIssue.denied => s.sosLocationDenied,
                LocationIssue.deniedForever => s.locationDeniedForever,
                _ => s.sosLocationNotFound,
              },
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: JSpace.md),
            if (issue == LocationIssue.serviceOff || issue == LocationIssue.deniedForever)
              FilledButton(
                onPressed: () {
                  final service = ref.read(locationServiceProvider);
                  issue == LocationIssue.serviceOff ? service.openLocationSettings() : service.openAppSettings();
                },
                child: Text(s.openSettings),
              ),
          ],
          const SizedBox(height: JSpace.sm),
          TextButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            label: Text(s.refresh),
          ),
        ],
      ),
    );
  }
}

class _Coordinate extends StatelessWidget {
  const _Coordinate({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          SelectableText(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
