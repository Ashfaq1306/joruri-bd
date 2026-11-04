import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/core/firebase/google_auth.dart';
import 'package:joruri_bd/core/remote/app_meta.dart';
import 'package:joruri_bd/features/update/update_installer.dart';
import 'package:joruri_bd/features/profile/data/profile_sync.dart';
import 'package:joruri_bd/features/profile/presentation/profile_card.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/features/settings/domain/app_settings.dart';
import 'package:joruri_bd/features/settings/presentation/permissions_section.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final lang = s.languageCode;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: JSpace.lg, bottom: JSpace.sm),
          child: Text(text, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(showLogo: true, title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(JSpace.md, 0, JSpace.md, 120),
        children: [
          heading(s.myProfile),
          const ProfileCard(),
          heading(s.language),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {settings.languageCode ?? lang},
            onSelectionChanged: (v) => controller.change((c) => c.copyWith(languageCode: v.first)),
          ),
          heading(s.theme),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(s.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(s.themeDark)),
              ButtonSegment(value: ThemeMode.system, label: Text(s.themeSystem)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (v) => controller.change((c) => c.copyWith(themeMode: v.first)),
          ),
          const SizedBox(height: JSpace.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.easyMode, style: theme.textTheme.titleMedium),
            subtitle: Text(s.easyModeBody),
            value: settings.easyMode,
            onChanged: (v) => controller.change((c) => c.copyWith(easyMode: v)),
          ),

          heading(s.sosSettings),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.contacts),
            title: Text(s.emergencyContacts, style: theme.textTheme.titleMedium),
            subtitle: Text(localizedDigits(
              '${ref.watch(contactsProvider).length}/${AppConfig.maxEmergencyContacts}',
              lang,
            )),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/contacts'),
          ),
          Text(s.sosMode, style: theme.textTheme.titleSmall),
          const SizedBox(height: JSpace.sm),
          ChoiceCard(
            title: s.sosModeCountdown,
            subtitle: s.sosModeCountdownBody,
            selected: settings.sosMode == SosMode.countdown,
            onTap: () => controller.change((c) => c.copyWith(sosMode: SosMode.countdown)),
          ),
          const SizedBox(height: JSpace.sm),
          ChoiceCard(
            title: s.sosModeInstant,
            subtitle: s.sosModeInstantBody,
            selected: settings.sosMode == SosMode.instant,
            onTap: () => controller.change((c) => c.copyWith(sosMode: SosMode.instant)),
          ),
          if (settings.sosMode == SosMode.countdown) ...[
            const SizedBox(height: JSpace.md),
            Text(s.countdownLength, style: theme.textTheme.titleSmall),
            const SizedBox(height: JSpace.sm),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final n in const [3, 5])
                  ButtonSegment(value: n, label: Text(localizedDigits(s.seconds(n), lang))),
              ],
              selected: {settings.countdownSeconds},
              onSelectionChanged: (v) => controller.change((c) => c.copyWith(countdownSeconds: v.first)),
            ),
          ],
          const SizedBox(height: JSpace.md),
          Text(s.smsLanguage, style: theme.textTheme.titleSmall),
          const SizedBox(height: JSpace.sm),
          SegmentedButton<SosMessageLanguage>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: SosMessageLanguage.en, label: Text('English')),
              ButtonSegment(value: SosMessageLanguage.bn, label: Text('বাংলা')),
            ],
            selected: {settings.smsLanguage},
            onSelectionChanged: (v) => controller.change((c) => c.copyWith(smsLanguage: v.first)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: JSpace.xs),
            child: Text(s.smsLanguageHint, style: theme.textTheme.bodySmall),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.includeLocation, style: theme.textTheme.titleMedium),
            subtitle: Text(s.includeLocationBody),
            value: settings.includeLocation,
            onChanged: (v) => controller.change((c) => c.copyWith(includeLocation: v)),
          ),
          const SizedBox(height: JSpace.sm),
          _ExtraLineField(initial: settings.extraLine),
          const SizedBox(height: JSpace.sm),
          OutlinedButton.icon(
            onPressed: () => _showPreview(context, ref),
            icon: const Icon(Icons.visibility),
            label: Text(s.previewMessage),
          ),

          heading(s.permissions),
          const PermissionsSection(),

          heading(s.privacy),
          Text(s.privacyBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: JSpace.md),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: JColors.sos),
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: Text(s.deleteLocalData),
          ),

          heading(s.about),
          const _AboutSection(),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final settings = ref.read(settingsProvider);
    final example = SosMessageBuilder.build(
      language: settings.smsLanguage,
      now: DateTime.now(),
      location: settings.includeLocation
          ? SosLocation(latitude: 23.81030, longitude: 90.41250, accuracyMeters: 15, fixTime: DateTime.now())
          : null,
      extraLine: settings.extraLine,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.previewMessage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.exampleMessage, style: Theme.of(dialogContext).textTheme.bodySmall),
            const SizedBox(height: JSpace.sm),
            SelectableText(example),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s.close))],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final s = context.s;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteLocalData),
        content: Text(s.deleteLocalDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: JColors.sos),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (!(yes ?? false)) return;
    // Removes the online profile (an admin-hidden listing is switched off
    // instead of deleted) and signs out of Firebase and Google.
    await ref.read(profileSyncProvider).removeAndSignOut();
    await ref.read(googleAuthProvider).signOut();
    await ref.read(sharedPreferencesProvider).clear();
    ref
      ..invalidate(contactsProvider)
      ..invalidate(profileProvider)
      ..invalidate(settingsProvider);
    // Onboarding is reset too, so the router returns to the welcome screen.
  }
}

class _ExtraLineField extends ConsumerStatefulWidget {
  const _ExtraLineField({required this.initial});

  final String initial;

  @override
  ConsumerState<_ExtraLineField> createState() => _ExtraLineFieldState();
}

class _ExtraLineFieldState extends ConsumerState<_ExtraLineField> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsProvider.notifier).change((c) => c.copyWith(extraLine: _text.text.trim()));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return TextField(
      controller: _text,
      maxLength: SosMessageBuilder.maxExtraLineLength,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      onTapOutside: (_) => _save(),
      decoration: InputDecoration(
        labelText: s.extraLine,
        hintText: s.extraLineHint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// App version (from the installed package) and the update check.
class _AboutSection extends ConsumerStatefulWidget {
  const _AboutSection();

  @override
  ConsumerState<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends ConsumerState<_AboutSection> {
  bool _checking = false;

  Future<void> _check() async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    final reached = await ref.read(refreshAppMetaProvider)();
    // Give the live listener a moment to deliver the newest settings.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _checking = false);
    final update = ref.read(updateInfoProvider);
    if (update != null) {
      // Downloads inside the app and opens Android's installer.
      messenger.showSnackBar(SnackBar(content: Text(s.updateDownloading(null))));
      await ref.read(updateInstallerProvider.notifier).downloadAndInstall(update);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(reached ? s.upToDate : s.updatesCheckFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final update = ref.watch(updateInfoProvider);
    final version = info == null ? '' : '${info.version} (${baseBuildNumber(info.buildNumber)})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.appName} · ${s.version} ${localizedDigits(version, s.languageCode)}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: JSpace.sm),
        OutlinedButton.icon(
          onPressed: _checking ? null : _check,
          icon: _checking
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(update != null ? Icons.download : Icons.system_update),
          label: Text(_checking ? s.checking : (update != null ? s.updateDownload : s.checkForUpdates)),
        ),
      ],
    );
  }
}
