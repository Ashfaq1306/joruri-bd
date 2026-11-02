import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Emergency numbers for one category (police, fire, ambulance) or all.
class NumbersScreen extends ConsumerWidget {
  const NumbersScreen({super.key, required this.category});

  final NumberCategory? category;

  String _title(AppStrings s) => switch (category) {
        NumberCategory.police => s.tilePolice,
        NumberCategory.fire => s.tileFire,
        NumberCategory.ambulance => s.tileAmbulance,
        _ => s.emergencyNumbers,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final async = ref.watch(emergencyNumbersProvider);
    final filter = category;
    final showsStations = filter == NumberCategory.police ||
        filter == NumberCategory.fire ||
        filter == NumberCategory.ambulance;

    return Scaffold(
      appBar: GlassAppBar(title: Text(_title(s))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Fallback(message: s.genericError),
        data: (all) {
          final list = filter == null ? all : all.where((n) => n.serves(filter)).toList();
          if (list.isEmpty) return _Fallback(message: s.noNumbers);
          return ListView(
            padding: const EdgeInsets.all(JSpace.md),
            children: [
              for (final n in list) ...[NumberCard(number: n), const SizedBox(height: 12)],
              if (showsStations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
                  child: Text(s.localNumbersPending, style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// If content cannot load, 999 is still one tap away.
class _Fallback extends ConsumerWidget {
  const _Fallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(JSpace.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: JSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
            onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            icon: const Icon(Icons.call),
            label: Text(context.s.call999),
          ),
        ],
      ),
    );
  }
}

/// One verified (or clearly labelled) emergency number with a big call button.
class NumberCard extends ConsumerWidget {
  const NumberCard({super.key, required this.number});

  final EmergencyNumber number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final lang = s.languageCode;
    final v = number.verification;
    final sourceUrl = v.sourceUrl;
    final isNational = number.category == NumberCategory.national;

    return Container(
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? JColors.nightSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(140)),
        boxShadow: JShadows.soft(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  number.name.resolve(lang),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                number.number,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: JSpace.xs),
          Text(number.description.resolve(lang), style: theme.textTheme.bodyMedium),
          if (!v.isVerified) ...[
            const SizedBox(height: JSpace.sm),
            const UnverifiedLabel(),
          ],
          if (sourceUrl != null)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => launchUrl(Uri.parse(sourceUrl), mode: LaunchMode.externalApplication),
              child: Text('${s.sourceLabel}: ${v.sourceName ?? sourceUrl}'),
            ),
          const SizedBox(height: JSpace.xs),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: isNational
                  ? FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white)
                  : null,
              onPressed: () => ref.read(phoneServiceProvider).dial(number.number),
              icon: const Icon(Icons.call),
              label: Text(s.callNumber(number.number)),
            ),
          ),
        ],
      ),
    );
  }
}
