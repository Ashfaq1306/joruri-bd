import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Lets the person grant location and (Android) direct calls ahead of time,
/// so SOS never has to stop and ask during an emergency.
class PermissionsSection extends ConsumerStatefulWidget {
  const PermissionsSection({super.key});

  @override
  ConsumerState<PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<PermissionsSection> {
  bool? _location;
  bool? _calls;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final location = await ref.read(locationServiceProvider).hasPermission();
    final calls = await ref.read(phoneServiceProvider).hasDirectCallPermission();
    if (!mounted) return;
    setState(() {
      _location = location;
      _calls = calls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final phone = ref.read(phoneServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PermissionButton(
          icon: Icons.my_location,
          label: s.allowLocation,
          granted: _location ?? false,
          onPressed: () async {
            await ref.read(locationServiceProvider).requestPermission();
            await _refresh();
          },
        ),
        if (phone.supportsDirectCall) ...[
          const SizedBox(height: JSpace.sm),
          _PermissionButton(
            icon: Icons.call,
            label: s.allowCalls,
            granted: _calls ?? false,
            onPressed: () async {
              await phone.requestDirectCallPermission();
              await _refresh();
            },
          ),
        ],
      ],
    );
  }
}

class _PermissionButton extends StatelessWidget {
  const _PermissionButton({
    required this.icon,
    required this.label,
    required this.granted,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool granted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (granted) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, color: JColors.ok),
        label: Text('$label: ${s.allowed}'),
      );
    }
    return FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
  }
}
