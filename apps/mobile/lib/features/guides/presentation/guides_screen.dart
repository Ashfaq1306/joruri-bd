import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/directory/data/content_repository.dart';
import 'package:joruri_bd/features/guides/presentation/guide_icons.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// First aid and disaster guides. Bundled in the app: work fully offline.
class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final async = ref.watch(guidesProvider);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          showLogo: true,
          title: Text(s.guides),
          bottom: TabBar(tabs: [Tab(text: s.tileFirstAid), Tab(text: s.tileDisaster)]),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(s.genericError)),
          data: (guides) => TabBarView(
            children: [
              _GuideList(guides: guides.where((g) => g.kind == GuideKind.firstAid).toList()),
              _GuideList(guides: guides.where((g) => g.kind == GuideKind.disaster).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideList extends StatelessWidget {
  const _GuideList({required this.guides});

  final List<Guide> guides;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, 120),
      itemCount: guides.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final g = guides[i];
        final label = switch (g.reviewStatus) {
          ReviewStatus.draft => s.draftLabel,
          ReviewStatus.pending => s.pendingLabel,
          ReviewStatus.approved => null,
        };
        return ListTile(
          minVerticalPadding: 14,
          leading: CircleAvatar(
            backgroundColor: g.kind == GuideKind.firstAid ? JColors.firstAid : JColors.disaster,
            child: Icon(guideIcon(g.icon), color: Colors.white),
          ),
          title: Text(g.title.resolve(lang), style: theme.textTheme.titleMedium),
          subtitle: label == null ? null : Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/guide/${g.id}'),
        );
      },
    );
  }
}
