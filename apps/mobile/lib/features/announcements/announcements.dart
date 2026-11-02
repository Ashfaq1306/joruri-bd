import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/features/directory/data/content_cache.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

enum AnnouncementLevel {
  info,
  warning,
  urgent;

  static AnnouncementLevel parse(Object? v) =>
      AnnouncementLevel.values.firstWhere((l) => l.name == v, orElse: () => AnnouncementLevel.info);
}

/// A notice written on the admin website, shown on the home screen.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.level = AnnouncementLevel.info,
    this.linkUrl = '',
    this.linkLabel = const LocalizedText(en: '', bn: ''),
    this.startsAt,
    this.endsAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        title: LocalizedText.fromJson(j['title']),
        body: LocalizedText.fromJson(j['body']),
        level: AnnouncementLevel.parse(j['level']),
        linkUrl: (j['linkUrl'] as String?)?.trim() ?? '',
        linkLabel: LocalizedText.fromJson(j['linkLabel']),
        startsAt: j['startsAt'] as String?,
        endsAt: j['endsAt'] as String?,
      );

  final String id;
  final LocalizedText title;
  final LocalizedText body;
  final AnnouncementLevel level;

  /// https://…, tel:…, or app:/path for a screen inside the app.
  final String linkUrl;
  final LocalizedText linkLabel;

  /// Dates as yyyy-MM-dd, both days included. Null = no limit.
  final String? startsAt;
  final String? endsAt;

  bool activeOn(DateTime day) {
    final d = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final from = startsAt;
    final until = endsAt;
    if (from != null && from.isNotEmpty && d.compareTo(from) < 0) return false;
    if (until != null && until.isNotEmpty && d.compareTo(until) > 0) return false;
    return !(title.isEmpty && body.isEmpty);
  }
}

/// Every announcement downloaded from the website (none before the first download).
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final cache = await ref.watch(cachedContentProvider.future);
  return parseSection(cache, 'announcements', Announcement.fromJson) ?? const [];
});

const _dismissedKey = 'announcements.dismissed';

/// IDs the person closed on this phone. Urgent ones cannot be closed.
final dismissedAnnouncementsProvider =
    NotifierProvider<DismissedAnnouncements, Set<String>>(DismissedAnnouncements.new);

class DismissedAnnouncements extends Notifier<Set<String>> {
  @override
  Set<String> build() => {...?ref.watch(sharedPreferencesProvider).getStringList(_dismissedKey)};

  void dismiss(String id) {
    state = {...state, id};
    ref.read(sharedPreferencesProvider).setStringList(_dismissedKey, state.toList());
  }
}

/// Active, not dismissed, most urgent first.
final visibleAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final all = ref.watch(announcementsProvider).valueOrNull ?? const [];
  final dismissed = ref.watch(dismissedAnnouncementsProvider);
  final now = DateTime.now();
  return all
      .where((a) => a.activeOn(now) && (a.level == AnnouncementLevel.urgent || !dismissed.contains(a.id)))
      .toList()
    ..sort((a, b) => b.level.index.compareTo(a.level.index));
});

class AnnouncementsList extends ConsumerWidget {
  const AnnouncementsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(visibleAnnouncementsProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final a in items)
          Padding(padding: const EdgeInsets.only(bottom: JSpace.sm), child: AnnouncementCard(announcement: a)),
      ],
    );
  }
}

class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final a = announcement;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color accent, IconData icon) = switch (a.level) {
      AnnouncementLevel.urgent => (JColors.sos, Icons.warning_rounded),
      AnnouncementLevel.warning => (const Color(0xFFB86E00), Icons.error_outline_rounded),
      AnnouncementLevel.info => (JColors.flagGreen, Icons.campaign_rounded),
    };
    final background = Color.alphaBlend(accent.withValues(alpha: dark ? 0.22 : 0.09), Theme.of(context).colorScheme.surface);
    final title = a.title.resolve(lang);
    final body = a.body.resolve(lang);
    final label = a.linkLabel.resolve(lang);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(JSize.radius),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.fromLTRB(JSpace.md, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: accent, size: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (a.linkUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => openAnnouncementLink(context, a.linkUrl),
                    child: Text(label.isEmpty ? s.openLink : label),
                  ),
                ],
              ],
            ),
          ),
          if (a.level != AnnouncementLevel.urgent)
            IconButton(
              tooltip: s.close,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => ref.read(dismissedAnnouncementsProvider.notifier).dismiss(a.id),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

/// app:/blood opens a screen in the app; anything else opens outside it.
Future<void> openAnnouncementLink(BuildContext context, String link) async {
  if (link.startsWith('app:')) {
    final path = link.substring(4);
    if (path.startsWith('/')) context.push(path);
    return;
  }
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
