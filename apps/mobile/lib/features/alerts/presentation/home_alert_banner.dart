import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_style.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// On the home screen: the most serious active alert for the person's
/// district (or the whole country), with one tap to "what to do".
/// Nothing is shown when there is no alert.
class HomeAlertBanner extends ConsumerWidget {
  const HomeAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final district = ref.watch(alertDistrictProvider);
    final everywhere = ref.watch(alertSettingsProvider.select((x) => x.everywhere));
    final alerts = [
      for (final a in ref.watch(activeAlertsProvider))
        if (a.level.index >= AlertLevel.watch.index && (a.concerns(district) || (everywhere && a.districts.isNotEmpty))) a,
    ];
    if (alerts.isEmpty) return const SizedBox.shrink();
    final a = alerts.first;
    final color = AlertStyle.color(a.level);
    final on = AlertStyle.onColor(a.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.sm),
      child: Semantics(
        button: true,
        liveRegion: true,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(JSize.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(JSize.radius),
            onTap: () => context.push(alerts.length == 1 ? '/alerts/${Uri.encodeComponent(a.id)}' : '/alerts'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(JSpace.md, 12, 8, 12),
              child: Row(
                children: [
                  Icon(AlertStyle.icon(a.hazard), color: on, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AlertStyle.level(s, a.level)} · ${AlertStyle.hazard(s, a.hazard)}',
                          style: TextStyle(color: on, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.headline.resolve(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: on, fontWeight: FontWeight.w700, fontSize: 16, height: 1.25),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alerts.length > 1 ? s.moreAlerts(alerts.length - 1) : s.tapForWhatToDo,
                          style: TextStyle(color: on.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: on),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
