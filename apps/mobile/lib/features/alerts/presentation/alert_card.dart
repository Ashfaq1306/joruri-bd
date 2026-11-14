import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/alerts/presentation/alert_style.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// One alert in a list: colour stripe by level, hazard icon, headline, area, time.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert});

  final HazardAlert alert;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final a = alert;
    final color = AlertStyle.color(a.level);
    final area = a.nationwide
        ? s.wholeCountry
        : a.areaText.resolve(lang).isNotEmpty
            ? a.areaText.resolve(lang)
            : a.districts.map((d) => BdLocations.district(d)?.name(lang) ?? d).take(6).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/alerts/${Uri.encodeComponent(a.id)}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: color,
                            child: Icon(AlertStyle.icon(a.hazard), color: AlertStyle.onColor(a.level)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    LevelChip(level: a.level),
                                    Text(AlertStyle.hazard(s, a.hazard),
                                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(a.headline.resolve(lang),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                                if (area.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(area,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${AlertStyle.source(s, a.source)} · ${formatAlertTime(a.sent, lang)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level, this.large = false});

  final AlertLevel level;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = AlertStyle.color(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 5 : 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
      child: Text(
        AlertStyle.level(context.s, level),
        style: TextStyle(
          color: AlertStyle.onColor(level),
          fontWeight: FontWeight.w700,
          fontSize: large ? 14 : 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A rounded section card used on the alert screens.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(JSpace.md)});

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}
