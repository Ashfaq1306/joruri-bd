import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/remote/app_meta.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Opens the new APK in the browser, which downloads it; the person then
/// taps Install. (Apps outside Google Play cannot install themselves.)
Future<void> downloadUpdate(BuildContext context, AppMeta meta) async {
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

/// "Update available" card on the home screen. A normal update can be put
/// off until the next version; a required one stays until the app is updated.
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateInfoProvider);
    if (update == null) return const SizedBox.shrink();
    final prefs = ref.watch(sharedPreferencesProvider);
    if (!update.required && prefs.getInt(_dismissedKey) == update.meta.latestVersionCode) {
      return const SizedBox.shrink();
    }

    final s = context.s;
    final theme = Theme.of(context);
    final accent = update.required ? JColors.sos : JColors.flagGreen;
    final notes = update.notes.resolve(s.languageCode);

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
                    update.required ? s.updateRequired : s.updateAvailable,
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
            Row(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () => downloadUpdate(context, update.meta),
                  icon: const Icon(Icons.download),
                  label: Text(s.updateDownload),
                ),
                const SizedBox(width: 8),
                if (!update.required)
                  TextButton(
                    onPressed: () {
                      prefs.setInt(_dismissedKey, update.meta.latestVersionCode);
                      setState(() {});
                    },
                    child: Text(s.later),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
