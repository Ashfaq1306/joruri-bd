import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/profile/presentation/profile_form.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Create or edit the account from Settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<ProfileFormState>();

  Future<void> _save() async {
    final profile = _formKey.currentState?.submit();
    if (profile == null) return;
    // Saved on the phone at once (works offline). The online update runs in
    // the background; its result shows on the profile card in Settings.
    await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.syncSavedLocal)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final exists = ref.watch(profileProvider) != null;
    return Scaffold(
      appBar: GlassAppBar(title: Text(exists ? s.editProfile : s.createAccount)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, JSpace.xl),
        children: [
          ProfileForm(key: _formKey),
          const SizedBox(height: JSpace.lg),
          FilledButton(onPressed: _save, child: Text(exists ? s.save : s.saveAccount)),
        ],
      ),
    );
  }
}
