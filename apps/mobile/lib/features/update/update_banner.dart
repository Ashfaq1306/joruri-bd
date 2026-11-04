import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/remote/app_meta.dart';
import 'package:joruri_bd/features/update/update_installer.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// The old way, kept as a fallback: open the APK link in the browser, which
/// downloads it; the person then opens the file and taps Install.
Future<void> downloadInBrowser(BuildContext context, AppMeta meta) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = await apkUriFor(meta);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  messenger?.showSnackBar(SnackBar(content: Text(ok ? s.downloadStarted : s.updatesCheckFailed)));
}

const _dismissedKey = 'update.dismissedVersion';

/// "Update available" card on the home screen. The update downloads inside
/// the app (by itself on Wi-Fi) and installs with one tap. A normal update
/// can be put off until the next version; a required one stays.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  @override
  Widget build(BuildContext context) {
    final download = ref.watch(updateInstallerProvider);
    final update = ref.watch(updateInfoProvider);
    if (update == null) return const SizedBox.shrink();
    final prefs = ref.watch(sharedPreferencesProvider);
    final ready = download.versionCode == update.meta.latestVersionCode &&
        (download.stage == UpdateStage.ready || download.stage == UpdateStage.needsPermission);
    // A downloaded update is always shown: installing it is one tap.
    if (!update.required && !ready && prefs.getInt(_dismissedKey) == update.meta.latestVersionCode) {
      return const SizedBox.shrink();
    }

    final s = context.s;
    final theme = Theme.of(context);
    final accent = update.required ? JColors.sos : JColors.flagGreen;
    final notes = update.notes.resolve(s.languageCode);
    final installer = ref.read(updateInstallerProvider.notifier);
    final mine = download.versionCode == update.meta.latestVersionCode;
    final stage = mine ? download.stage : UpdateStage.idle;

    final Widget action;
    switch (stage) {
      case UpdateStage.downloading:
        final p = download.progress;
        action = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.updateDownloading(p == null ? null : (p * 100).round()), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: p, color: accent),
          ],
        );
      case UpdateStage.ready:
      case UpdateStage.needsPermission:
        action = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stage == UpdateStage.needsPermission) ...[
              Text(s.updateAllowInstall, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
            ],
            _button(accent, Icons.system_update, s.updateInstall, installer.install),
          ],
        );
      case UpdateStage.failed:
        action = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.updateDownloadFailed, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _button(accent, Icons.refresh, s.retry, () => installer.downloadAndInstall(update)),
                OutlinedButton(onPressed: () => downloadInBrowser(context, update.meta), child: Text(s.updateInBrowser)),
              ],
            ),
          ],
        );
      case UpdateStage.idle:
        action = Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _button(accent, Icons.download, s.updateDownload, () => installer.downloadAndInstall(update)),
            if (!update.required)
              TextButton(
                onPressed: () {
                  prefs.setInt(_dismissedKey, update.meta.latestVersionCode);
                  setState(() {});
                },
                child: Text(s.later),
              ),
          ],
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withValues(alpha: 0.1), theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(JSize.radius),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(JSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(update.required ? Icons.system_update_alt : Icons.new_releases_outlined, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ready ? s.updateReady : (update.required ? s.updateRequired : s.updateAvailable),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(update.required ? s.updateRequiredBody : s.updateBody(update.versionName)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${s.whatsNew}: $notes', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            action,
          ],
        ),
      ),
    );
  }

  // White text on the green/red button (the old dark text was hard to read).
  Widget _button(Color accent, IconData icon, String label, VoidCallback onPressed) => FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
}
