import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/alerts/data/alert_notifications.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_card.dart';
import 'package:joruri_bd/features/alerts/presentation/alert_style.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Disaster alerts: live warnings for the person's district and the rest of
/// the country, and how to get ready (earthquake alerts on Android, storm
/// signals, the emergency bag, the disaster guides).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _refreshing = false;
  bool? _notificationsOn;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    final on = await ref.read(alertNotificationsProvider).enabled();
    if (mounted) setState(() => _notificationsOn = on);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final fresh = await fetchOfficialAlerts();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (fresh == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.alertsOffline)));
    } else {
      ref.read(refreshedAlertsProvider.notifier).state = fresh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final feed = ref.watch(alertFeedProvider).valueOrNull ?? const AlertFeed();
    final active = ref.watch(activeAlertsProvider);
    final district = ref.watch(alertDistrictProvider);
    final settings = ref.watch(alertSettingsProvider);
    final now = DateTime.now().toUtc();
    final mine = [for (final a in active) if (a.concerns(district)) a];
    final others = [for (final a in active) if (!a.concerns(district)) a];
    final districtName = district == null ? null : BdLocations.district(district)?.name(lang);

    Widget heading(String text, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(4, JSpace.md, 4, JSpace.sm),
          child: Row(
            children: [
              Expanded(child: Text(text, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              if (trailing != null) trailing,
            ],
          ),
        );

    return Scaffold(
      appBar: GlassAppBar(
        title: Text(s.disasterAlerts),
        actions: [
          IconButton(
            tooltip: s.refresh,
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.sm, JSpace.md, JSpace.xl),
          children: [
            _AreaCard(districtName: districtName, everywhere: settings.everywhere),
            if (_notificationsOn == false && settings.notify)
              SectionCard(
                color: AlertStyle.color(AlertLevel.watch).withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_off_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.notificationsOffBody, style: theme.textTheme.bodyMedium)),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(alertNotificationsProvider).requestPermission();
                        _checkNotifications();
                      },
                      child: Text(s.turnOn),
                    ),
                  ],
                ),
              ),
            heading(districtName == null ? s.alertsForYou : s.alertsFor(districtName)),
            if (district == null)
              SectionCard(child: Text(s.chooseAlertDistrict, style: theme.textTheme.bodyLarge))
            else if (mine.isEmpty)
              SectionCard(
                color: JColors.ok.withValues(alpha: 0.10),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: JColors.ok, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.noAlertsHere(districtName ?? ''), style: theme.textTheme.titleMedium)),
                  ],
                ),
              )
            else
              for (final a in mine) AlertCard(alert: a),
            if (others.isNotEmpty) ...[
              heading(district == null ? s.activeAlerts : s.elsewhereInBangladesh),
              for (final a in others) AlertCard(alert: a),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: Text(
                [
                  if (feed.checkedAt != null) s.alertsChecked(formatAgo(s, feed.checkedAt!, now)),
                  s.alertSourcesNote,
                ].join(' '),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            heading(s.getReady),
            const _EarthquakeAlertsCard(),
            _LinkCard(
              icon: Icons.flag_outlined,
              color: const Color(0xFFC62828),
              title: s.cycloneSignals,
              subtitle: s.cycloneSignalsSub,
              onTap: () => context.push('/alerts/signals'),
            ),
            _LinkCard(
              icon: Icons.backpack_outlined,
              color: JColors.disaster,
              title: s.emergencyBag,
              subtitle: s.emergencyBagSub,
              onTap: () => _showBag(context),
            ),
            _LinkCard(
              icon: Icons.menu_book_outlined,
              color: JColors.firstAid,
              title: s.disasterGuides,
              subtitle: s.disasterGuidesSub,
              onTap: () => context.go('/guides?tab=1'),
            ),
            _LinkCard(
              icon: Icons.support_agent,
              color: JColors.hospital,
              title: localizedDigits(s.call1090, lang),
              subtitle: s.call1090Sub,
              onTap: () => ref.read(phoneServiceProvider).dial('1090'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBag(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
          children: [
            Text(s.emergencyBag, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: JSpace.sm),
            Text(s.emergencyBagIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: JSpace.md),
            for (final item in s.emergencyBagItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: JColors.ok, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends ConsumerWidget {
  const _AreaCard({required this.districtName, required this.everywhere});

  final String? districtName;
  final bool everywhere;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(JSpace.md, 12, 8, 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: JColors.flagGreen.withValues(alpha: 0.12),
            child: const Icon(Icons.my_location, color: JColors.flagGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.myAlertArea, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(districtName ?? s.notChosen, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (everywhere) Text(s.notifyWholeCountryOn, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await pickAlertDistrict(context, ref.read(alertDistrictProvider));
              if (picked != null) ref.read(alertSettingsProvider.notifier).setDistrict(picked);
            },
            child: Text(s.change),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with the 64 districts, grouped by division.
Future<String?> pickAlertDistrict(BuildContext context, String? current) {
  final s = context.s;
  final lang = s.languageCode;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.sm),
            child: Text(s.chooseYourDistrict,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          for (final div in BdLocations.divisions) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, 4),
              child: Text(div.name(lang),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            for (final d in BdLocations.districts.where((d) => d.divisionId == div.id))
              ListTile(
                title: Text(d.name(lang)),
                trailing: d.id == current ? const Icon(Icons.check, color: JColors.ok) : null,
                onTap: () => Navigator.of(context).pop(d.id),
              ),
          ],
        ],
      ),
    ),
  );
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Only the phone itself can warn before shaking arrives: the Android
/// Earthquake Alerts System (Google), available in Bangladesh since 2022.
class _EarthquakeAlertsCard extends StatelessWidget {
  const _EarthquakeAlertsCard();

  Future<void> _open() async {
    if (!Platform.isAndroid) return;
    for (final action in const ['android.settings.LOCATION_SOURCE_SETTINGS', 'android.settings.SETTINGS']) {
      try {
        await AndroidIntent(action: action).launch();
        return;
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    const color = Color(0xFF6A1B9A);
    return SectionCard(
      color: color.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: color, child: Icon(Icons.vibration, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.earthquakeEarlyWarning,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: JSpace.sm),
          Text(s.earthquakeEarlyWarningBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.sm),
          Text(s.earthquakeEarlyWarningSteps, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: JSpace.sm),
          OutlinedButton.icon(onPressed: _open, icon: const Icon(Icons.settings), label: Text(s.openPhoneSettings)),
        ],
      ),
    );
  }
}
