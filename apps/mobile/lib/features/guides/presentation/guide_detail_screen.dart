import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/unverified_label.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// One guide: do now, do not, get help, who to contact. A 999 button is
/// always pinned at the bottom.
class GuideDetailScreen extends ConsumerWidget {
  const GuideDetailScreen({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final guides = ref.watch(guidesProvider).valueOrNull ?? const <Guide>[];
    Guide? guide;
    for (final g in guides) {
      if (g.id == guideId) guide = g;
    }

    Widget section(String title, List<String> lines) {
      if (lines.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: JSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: JSpace.sm),
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${localizedDigits('${i + 1}', lang)}.',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text(lines[i], style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final g = guide;
    return Scaffold(
      appBar: GlassAppBar(title: Text(g?.title.resolve(lang) ?? s.guides)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.xl),
        children: [
          if (g == null || !g.hasContent)
            Padding(
              padding: const EdgeInsets.only(top: JSpace.md),
              child: Text(s.guidePending, style: theme.textTheme.titleMedium),
            )
          else ...[
            if (g.reviewStatus == ReviewStatus.draft)
              UnverifiedLabel(text: s.draftBanner),
            if (g.reviewStatus == ReviewStatus.pending)
              UnverifiedLabel(text: s.guidePending),
            section(s.whatToDoNow, g.doNow.resolve(lang)),
            section(s.whatNotToDo, g.doNot.resolve(lang)),
            section(s.whenToGetHelp, g.getHelp.resolve(lang)),
            if (!g.whoToContact.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: JSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.whoToContact, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: JSpace.sm),
                    Text(g.whoToContact.resolve(lang), style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.md),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
            onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
            icon: const Icon(Icons.call),
            label: Text(s.call999),
          ),
        ),
      ),
    );
  }
}
