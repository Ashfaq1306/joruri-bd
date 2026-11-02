import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/features/toolkit/presentation/toolkit_controllers.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

class ToolkitScreen extends ConsumerWidget {
  const ToolkitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final torch = ref.watch(torchProvider);
    final sirenOn = ref.watch(sirenProvider);

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.tileToolkit)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          _ToolCard(
            icon: Icons.flashlight_on,
            color: JColors.toolkit,
            title: s.flashlight,
            subtitle: torch == TorchState.unavailable ? s.flashlightUnavailable : null,
            action: FilledButton(
              onPressed: torch == TorchState.unavailable
                  ? null
                  : () => ref.read(torchProvider.notifier).toggle(),
              child: Text(torch == TorchState.on ? s.turnOff : s.turnOn),
            ),
          ),
          _ToolCard(
            icon: Icons.campaign,
            color: JColors.sos,
            title: s.siren,
            subtitle: s.sirenHint,
            action: FilledButton(
              style: sirenOn
                  ? FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white)
                  : null,
              onPressed: () => ref.read(sirenProvider.notifier).toggle(),
              child: Text(sirenOn ? s.turnOff : s.turnOn),
            ),
          ),
          const _BatteryCard(),
          _LinkTile(icon: Icons.explore, title: s.compass, onTap: () => context.push('/toolkit/compass')),
          _LinkTile(icon: Icons.my_location, title: s.gpsCoordinates, onTap: () => context.push('/location')),
          _LinkTile(icon: Icons.contacts, title: s.emergencyContacts, onTap: () => context.push('/contacts')),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.action,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(JSpace.md),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? JColors.nightSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(140)),
          boxShadow: JShadows.soft(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: JSpace.sm),
              Text(subtitle!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }
}

class _BatteryCard extends StatefulWidget {
  const _BatteryCard();

  @override
  State<_BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<_BatteryCard> {
  final _battery = Battery();
  int? _level;
  BatteryState? _state;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (!mounted) return;
      setState(() {
        _level = level;
        _state = state;
      });
    } catch (_) {
      // Some emulators and tablets report nothing; the card then stays empty.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final level = _level;
    final low = level != null && level <= 20 && _state != BatteryState.charging;
    return _ToolCard(
      icon: low ? Icons.battery_alert : Icons.battery_std,
      color: low ? JColors.warning : JColors.ok,
      title: level == null
          ? s.battery
          : '${s.battery}: ${localizedDigits(s.batteryLevel(level), s.languageCode)}'
              '${_state == BatteryState.charging ? ' · ${s.charging}' : ''}',
      subtitle: low ? s.lowBatteryTip : null,
      action: OutlinedButton(onPressed: _read, child: Text(s.refresh)),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        minVerticalPadding: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JSize.radius),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
