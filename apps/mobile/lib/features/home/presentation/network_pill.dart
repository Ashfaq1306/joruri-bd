import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/connectivity/network_status.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Green "Online" or orange "Offline", shown once the first real check is done.
class NetworkPill extends ConsumerWidget {
  const NetworkPill({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final status = ref.watch(networkStatusProvider).valueOrNull;
    // Still checking: show nothing rather than a wrong "Offline".
    if (status == null) return const SizedBox.shrink();
    final online = status == NetworkStatus.online;
    return StatusPill(
      label: online ? s.online : s.offline,
      dotColor: online ? JColors.online : JColors.offline,
      onDark: onDark,
    );
  }
}
