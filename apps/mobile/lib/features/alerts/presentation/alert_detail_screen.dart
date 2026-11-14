import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_card.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_style.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// One alert: what is happening, where, until when, and what to do now.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final feed = ref.watch(alertFeedProvider).valueOrNull ?? const AlertFeed();
    HazardAlert? alert;
    for (final a in [...feed.team, ...feed.official, ...ref.watch(refreshedAlertsProvider)]) {
      if (a.id == alertId) alert = a;
    }
    final a = alert;
    if (a == null) {
      return Scaffold(
        appBar: GlassAppBar(title: Text(s.disasterAlerts)),
        body: ListView(
          padding: const EdgeInsets.all(JSpace.md),
          children: [
            Text(s.alertNotFound, style: theme.textTheme.titleMedium),
            const SizedBox(height: JSpace.md),
            FilledButton(onPressed: () => context.pushReplacement('/alerts'), child: Text(s.disasterAlerts)),
          ],
        ),
      );
    }

    final color = AlertStyle.color(a.level);
    final on = AlertStyle.onColor(a.level);
    final now = DateTime.now().toUtc();
    final expired = !a.activeAt(now);
    final guides = ref.watch(guidesProvider).valueOrNull ?? const <Guide>[];
    final related = [
      for (final id in a.hazard.guideIds)
        for (final g in guides)
          if (g.id == id && g.hasContent) g,
    ];
    final signal = StormSignal.of(a.signal);
    final quake = a.quake;
    final area = a.nationwide
        ? s.wholeCountry
        : [
            if (a.areaText.resolve(lang).isNotEmpty) a.areaText.resolve(lang),
          ].join();
    final districtNames = a.districts.map((d) => BdLocations.district(d)?.name(lang) ?? d).toList();

    Widget infoRow(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '$label\n', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  TextSpan(text: value, style: theme.textTheme.bodyLarge),
                ])),
              ),
            ],
          ),
        );

    Widget steps(List<String> lines) => Column(
          children: [
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Text(localizedDigits('${i + 1}', lang),
                          style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(lines[i], style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        );

    final firstGuide = related.isEmpty ? null : related.first;
    return Scaffold(
      appBar: GlassAppBar(title: Text(AlertStyle.hazard(s, a.hazard))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.xl),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(JSpace.md),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AlertStyle.icon(a.hazard), color: on, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AlertStyle.level(s, a.level).toUpperCase(),
                        style: TextStyle(color: on, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 15),
                      ),
                    ),
                    if (signal != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: on.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                        child: Text(localizedDigits(s.signalNo(signal.number), lang),
                            style: TextStyle(color: on, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(a.headline.resolve(lang),
                    style: theme.textTheme.titleLarge?.copyWith(color: on, fontWeight: FontWeight.w800, height: 1.25)),
                if (expired) ...[
                  const SizedBox(height: 8),
                  Text(s.alertEnded, style: TextStyle(color: on, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: JSpace.md),

          // What to do
          if (signal != null)
            SectionCard(
              color: color.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizedDigits('${s.signalNo(signal.number)}: ${signal.name.resolve(lang)}', lang),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(signal.meaning.resolve(lang), style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Text(s.whatToDoNow, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(signal.whatToDo.resolve(lang), style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          if (!a.instruction.isEmpty)
            SectionCard(
              color: color.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_outlined, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.officialAdvice(AlertStyle.source(s, a.source)),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.instruction.resolve(lang), style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          if (firstGuide != null && !expired) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, JSpace.sm, 4, JSpace.sm),
              child: Text(s.whatToDoNow, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  steps((a.hazard == Hazard.earthquake ? firstGuide.after : firstGuide.doNow).resolve(lang).isNotEmpty
                      ? (a.hazard == Hazard.earthquake ? firstGuide.after : firstGuide.doNow).resolve(lang)
                      : firstGuide.doNow.resolve(lang)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in related)
                        OutlinedButton.icon(
                          onPressed: () => context.push('/guide/${g.id}'),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: Text(s.fullGuide(g.title.resolve(lang))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(4, JSpace.sm, 4, JSpace.sm),
            child: Text(s.alertDetails, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quake != null) ...[
                  infoRow(Icons.speed, s.magnitude, localizedDigits(quake.magnitude.toStringAsFixed(1), lang)),
                  if (quake.depthKm != null)
                    infoRow(Icons.vertical_align_bottom, s.depth, localizedDigits(s.km(quake.depthKm!.round()), lang)),
                  if (quake.place.isNotEmpty) infoRow(Icons.public, s.epicentre, quake.place),
                ],
                infoRow(Icons.schedule, quake != null ? s.happenedAt : s.issuedAt, formatAlertTime(a.sent, lang)),
                if (a.expires != null && quake == null) infoRow(Icons.timer_outlined, s.validUntil, formatAlertTime(a.expires!, lang)),
                if (area.isNotEmpty) infoRow(Icons.place_outlined, s.area, area),
                if (districtNames.isNotEmpty && !a.nationwide)
                  infoRow(Icons.map_outlined, s.districtsCovered(districtNames.length), districtNames.join(', ')),
                infoRow(Icons.verified_outlined, s.sourceLabel, AlertStyle.source(s, a.source)),
              ],
            ),
          ),
          if (!a.description.isEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullBulletin, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(a.description.resolve(lang), style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                ],
              ),
            ),
          if (quake != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, JSpace.sm),
              child: Text(s.quakeNotPredicted, style: theme.textTheme.bodySmall),
            ),
          if (a.web.isNotEmpty)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(a.web), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: Text(s.openOfficialPage),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.md),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
                  onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
                  icon: const Icon(Icons.call),
                  label: Text(localizedDigits('999', lang)),
                ),
              ),
              const SizedBox(width: JSpace.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(phoneServiceProvider).dial('1090'),
                  icon: const Icon(Icons.support_agent),
                  label: Text(localizedDigits('1090', lang)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
