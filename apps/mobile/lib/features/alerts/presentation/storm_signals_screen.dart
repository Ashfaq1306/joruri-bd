import 'package:flutter/material.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_card.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_style.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// The 11 sea-port storm signals and what to do at each, so people can act
/// on the number they hear on the radio or from CPP volunteers.
class StormSignalsScreen extends StatelessWidget {
  const StormSignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GlassAppBar(title: Text(s.cycloneSignals)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.xl),
        children: [
          Text(s.cycloneSignalsIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          for (final sig in StormSignal.all)
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AlertStyle.color(sig.level), borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      localizedDigits('${sig.number}', lang),
                      style: TextStyle(color: AlertStyle.onColor(sig.level), fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sig.name.resolve(lang), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(sig.meaning.resolve(lang), style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(sig.whatToDo.resolve(lang),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(s.cycloneSignalsSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
