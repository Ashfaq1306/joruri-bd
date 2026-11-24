import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/app/router.dart';
import 'package:joruri_bd/core/platform/location_service.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Whether SOS could read the location now (null until the first check).
/// The home screen shows a "Location is off" bar when it is not ready.
final locationAccessProvider = StateProvider<LocationAccess?>((ref) => null);

final locationPromptProvider = Provider<LocationPrompt>((ref) {
  final prompt = LocationPrompt(ref);
  ref.onDispose(prompt.dispose);
  return prompt;
});

/// Like bKash: when the app opens (and when it comes back after a while),
/// location that is off is turned on with Google's one-tap dialog, and
/// location that is not allowed is asked for, with a short reason first.
///
/// Never in the way of an emergency: nothing is shown on the SOS screens,
/// during onboarding, or more than once a session after "Not now".
class LocationPrompt with WidgetsBindingObserver {
  LocationPrompt(this._ref);

  final Ref _ref;
  bool _started = false;
  bool _busy = false;
  bool _declined = false;
  DateTime? _pausedAt;
  final _firstCheck = Completer<void>();

  /// Asking again after "Not now" waits for the app to be away this long.
  static const askAgainAfter = Duration(minutes: 30);
  static const _quietRoutes = ['/sos', '/onboarding', '/sign-in', '/accident'];

  /// Completes when the check at app start is over (asked, or nothing to
  /// ask), so the notification permission is never asked at the same time.
  Future<void> get firstCheckDone => _firstCheck.future;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(check().whenComplete(_completeFirst));
  }

  void dispose() {
    if (_started) WidgetsBinding.instance.removeObserver(this);
  }

  void _completeFirst() {
    if (!_firstCheck.isCompleted) _firstCheck.complete();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away >= askAgainAfter) _declined = false;
      // Coming back from the phone's settings (or anywhere): look again.
      unawaited(check());
    }
  }

  /// [userAsked]: tapped the "Location is off" bar, so ask even after
  /// "Not now" and on any screen.
  Future<void> check({bool userAsked = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final service = _ref.read(locationServiceProvider);
      var access = await service.access();
      _ref.read(locationAccessProvider.notifier).state = access;
      if (access == LocationAccess.ready) return;
      if (!userAsked && (_declined || !_ref.read(settingsProvider).onboardingDone || _onQuietRoute())) return;

      final context = _context();
      if (context == null || !context.mounted) return;

      if (access == LocationAccess.denied || access == LocationAccess.deniedForever) {
        final blocked = access == LocationAccess.deniedForever;
        final go = await _explain(context, blocked: blocked);
        if (!go) {
          _declined = true;
          return;
        }
        if (blocked) {
          await service.openAppSettings();
          return; // checked again when the person comes back
        }
        await service.requestPermission();
        access = await service.access();
        _ref.read(locationAccessProvider.notifier).state = access;
        if (access != LocationAccess.serviceOff) {
          if (access != LocationAccess.ready) _declined = true;
          return;
        }
      }

      // Permission is there, the location switch is off: one tap to turn
      // it on, straight away, as bKash does.
      final result = await service.turnOnService();
      if (result == TurnOnResult.declined) _declined = true;
      if (result != TurnOnResult.openedSettings) {
        _ref.read(locationAccessProvider.notifier).state = await service.access();
      }
    } finally {
      _busy = false;
    }
  }

  BuildContext? _context() => _ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;

  bool _onQuietRoute() {
    try {
      // The top-most screen, also one pushed over the tabs (SOS over Home).
      final path = _ref.read(routerProvider).state.matchedLocation;
      return _quietRoutes.any(path.startsWith);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _explain(BuildContext context, {required bool blocked}) async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => LocationExplainer(blocked: blocked),
    );
    return go ?? false;
  }
}

/// The short "why" shown before Android's own permission question.
class LocationExplainer extends StatelessWidget {
  const LocationExplainer({super.key, required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(JSpace.lg, 0, JSpace.lg, JSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: JColors.flagGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, size: 40, color: JColors.flagGreen),
            ),
          ),
          const SizedBox(height: JSpace.md),
          Text(
            blocked ? s.locationBlockedTitle : s.locationPermissionTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: JSpace.sm),
          Text(s.locationPromptBody, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          if (blocked) ...[
            const SizedBox(height: JSpace.sm),
            Text(s.locationBlockedBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: JSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(blocked ? Icons.settings : Icons.my_location),
            label: Text(blocked ? s.openSettings : s.allowLocation),
          ),
          const SizedBox(height: JSpace.sm),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.notNow),
          ),
        ],
      ),
    );
  }
}

/// On Home, while location is off or not allowed: one tap fixes it.
class HomeLocationBar extends ConsumerWidget {
  const HomeLocationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(locationAccessProvider);
    if (access == null || access == LocationAccess.ready) return const SizedBox.shrink();
    final s = context.s;
    const color = Color(0xFFB45309); // amber 700: readable with white text
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpace.sm),
      child: Semantics(
        button: true,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(JSize.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(JSize.radius),
            onTap: () => ref.read(locationPromptProvider).check(userAsked: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(JSpace.md, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          access == LocationAccess.serviceOff ? s.homeLocationOff : s.homeLocationNotAllowed,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, height: 1.25),
                        ),
                        const SizedBox(height: 2),
                        Text(s.tapToFix, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
