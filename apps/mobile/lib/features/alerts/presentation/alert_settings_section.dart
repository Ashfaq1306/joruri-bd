import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/features/alerts/data/alert_notifications.dart';
import 'package:joruri_bd/features/alerts/data/alerts_repository.dart';
import 'package:joruri_bd/features/alerts/presentation/alerts_screen.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Settings → Disaster alerts: notifications on/off, the district, or the whole country.
class AlertSettingsSection extends ConsumerWidget {
  const AlertSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final settings = ref.watch(alertSettingsProvider);
    final controller = ref.read(alertSettingsProvider.notifier);
    final district = ref.watch(alertDistrictProvider);
    final profileDistrict = ref.watch(profileProvider.select((p) => p?.districtId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.alertNotifications, style: theme.textTheme.titleMedium),
          subtitle: Text(s.alertNotificationsBody),
          value: settings.notify,
          onChanged: (v) async {
            controller.setNotify(v);
            if (v) await ref.read(alertNotificationsProvider).requestPermission();
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(s.myAlertArea, style: theme.textTheme.titleMedium),
          subtitle: Text(district == null
              ? s.notChosen
              : '${BdLocations.district(district)?.name(lang) ?? district}'
                  '${settings.districtId == null && profileDistrict != null ? ' · ${s.fromProfile}' : ''}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await pickAlertDistrict(context, district);
            if (picked != null) controller.setDistrict(picked);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.notifyWholeCountry, style: theme.textTheme.titleMedium),
          subtitle: Text(s.notifyWholeCountryBody),
          value: settings.everywhere,
          onChanged: settings.notify ? controller.setEverywhere : null,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(s.disasterAlerts, style: theme.textTheme.titleMedium),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/alerts'),
        ),
      ],
    );
  }
}
