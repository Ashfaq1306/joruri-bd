import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:share_plus/share_plus.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/sos/domain/sos_run_state.dart';
import 'package:joruri_bd/features/sos/presentation/sos_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

enum _Look { idle, working, ok, warning }

/// Shows what SOS has done, step by step, and what to do next.
class SosStatusScreen extends ConsumerWidget {
  const SosStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final run = ref.watch(sosControllerProvider);
    final controller = ref.read(sosControllerProvider.notifier);
    final hasContacts = ref.watch(contactsProvider).isNotEmpty;
    final location = run.location;

    final (locationLook, locationText) = switch (run.locationOutcome) {
      LocationOutcome.pending => (run.running ? _Look.working : _Look.idle, s.sosLocating),
      LocationOutcome.found => (_Look.ok, s.sosLocationFound),
      LocationOutcome.notFound => (_Look.warning, s.sosLocationNotFound),
      LocationOutcome.permissionDenied => (_Look.warning, s.sosLocationDenied),
      LocationOutcome.serviceOff => (_Look.warning, s.sosLocationServiceOff),
      LocationOutcome.disabledInSettings => (_Look.warning, s.sosLocationDisabled),
    };
    final (messageLook, messageText) = switch (run.messageOutcome) {
      MessageOutcome.pending => (run.running ? _Look.working : _Look.idle, s.sosPreparingMessage),
      MessageOutcome.opened => (_Look.ok, s.sosMessageOpened),
      MessageOutcome.failed => (_Look.warning, s.sosMessageFailed),
      MessageOutcome.noContacts => (_Look.warning, s.sosNoContacts),
    };
    final (callLook, callText) = switch (run.callOutcome) {
      CallOutcome.pending => (_Look.idle, ''),
      CallOutcome.waitingForReturn => (_Look.working, s.sosWaitingToCall(run.callTarget)),
      CallOutcome.started => (_Look.ok, s.sosCalling(run.callTarget)),
      CallOutcome.failed => (_Look.warning, s.sosCallFailed),
      CallOutcome.notReturned => (_Look.warning, s.sosNotCalled),
    };

    void close() {
      controller.cancel();
      context.go('/home');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Scaffold(
        appBar: GlassAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: JColors.sos,
          foregroundColor: Colors.white,
          title: Text(s.sosStatusTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(JSpace.md),
            children: [
              _StepRow(look: locationLook, title: s.sosStepLocation, detail: locationText),
              _StepRow(look: messageLook, title: s.sosStepMessage, detail: messageText),
              if (run.callOutcome != CallOutcome.pending)
                _StepRow(look: callLook, title: s.sosStepCall, detail: callText),
              if (run.callOutcome == CallOutcome.waitingForReturn) ...[
                const SizedBox(height: JSpace.sm),
                FilledButton.icon(
                  onPressed: controller.callNow,
                  icon: const Icon(Icons.call),
                  label: Text(s.sosCallNow),
                ),
              ],
              if (run.locationOutcome == LocationOutcome.permissionDenied ||
                  run.locationOutcome == LocationOutcome.serviceOff) ...[
                const SizedBox(height: JSpace.sm),
                OutlinedButton(
                  onPressed: () {
                    final service = ref.read(locationServiceProvider);
                    run.locationOutcome == LocationOutcome.serviceOff
                        ? service.openLocationSettings()
                        : service.openAppSettings();
                  },
                  child: Text(s.openSettings),
                ),
              ],
              if (location != null) ...[
                const SizedBox(height: JSpace.md),
                _CoordinatesCard(location: location),
              ],
              const SizedBox(height: JSpace.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: JColors.sos, foregroundColor: Colors.white),
                onPressed: () => ref.read(phoneServiceProvider).dial(AppConfig.nationalEmergencyNumber),
                icon: const Icon(Icons.emergency),
                label: Text(s.call999),
              ),
              if (!run.running && hasContacts) ...[
                const SizedBox(height: JSpace.sm),
                OutlinedButton.icon(
                  onPressed: controller.callAgain,
                  icon: const Icon(Icons.call),
                  label: Text(s.sosCallAgain),
                ),
                const SizedBox(height: JSpace.sm),
                OutlinedButton.icon(
                  onPressed: controller.resendMessage,
                  icon: const Icon(Icons.sms),
                  label: Text(s.sosSendAgain),
                ),
              ],
              if (run.message.isNotEmpty) ...[
                const SizedBox(height: JSpace.sm),
                OutlinedButton.icon(
                  onPressed: () => Share.share(run.message),
                  icon: const Icon(Icons.share),
                  label: Text(s.sosShareOther),
                ),
              ],
              const SizedBox(height: JSpace.xl),
              TextButton(onPressed: close, child: Text(s.sosSafeClose)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.look, required this.title, required this.detail});

  final _Look look;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget icon = switch (look) {
      _Look.working => const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
      _Look.ok => const Icon(Icons.check_circle, color: JColors.ok, size: 30),
      _Look.warning => const Icon(Icons.error, color: JColors.warning, size: 30),
      _Look.idle => Icon(Icons.radio_button_unchecked, color: theme.colorScheme.outline, size: 30),
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: JSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 32, child: Center(child: icon)),
            const SizedBox(width: JSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (detail.isNotEmpty) Text(detail, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinatesCard extends StatelessWidget {
  const _CoordinatesCard({required this.location});

  final SosLocation location;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(JSpace.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(JSize.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.sosReadCoordinates, style: theme.textTheme.bodyMedium),
          const SizedBox(height: JSpace.xs),
          SelectableText(
            location.coordinates,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${location.coordinates}\n${location.mapLink}'));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.copied)));
              },
              icon: const Icon(Icons.copy),
              label: Text(s.copy),
            ),
          ),
        ],
      ),
    );
  }
}
