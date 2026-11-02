import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/features/settings/domain/app_settings.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/features/sos/presentation/sos_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Full-screen red countdown with one huge Cancel button.
class SosCountdownScreen extends ConsumerStatefulWidget {
  const SosCountdownScreen({super.key});

  @override
  ConsumerState<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends ConsumerState<SosCountdownScreen> {
  Timer? _timer;
  late int _remaining;
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _remaining = settings.countdownSeconds;
    if (settings.sosMode == SosMode.instant) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
      return;
    }
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        _launch();
        return;
      }
      setState(() => _remaining--);
      HapticFeedback.heavyImpact();
    });
  }

  void _launch() {
    if (_launched || !mounted) return;
    _launched = true;
    _timer?.cancel();
    unawaited(ref.read(sosControllerProvider.notifier).start());
    context.pushReplacement('/sos/status');
  }

  void _cancel() {
    _timer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    const white = Colors.white;
    return Scaffold(
      backgroundColor: JColors.sos,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(JSpace.lg),
          child: Column(
            children: [
              const Spacer(),
              Text(
                s.sosSendingIn,
                textAlign: TextAlign.center,
                style: const TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.w600),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  localizedDigits('$_remaining', s.languageCode),
                  style: const TextStyle(color: white, fontSize: 160, fontWeight: FontWeight.w800, height: 1.1),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 88,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: white,
                    foregroundColor: JColors.sos,
                    textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _cancel,
                  child: Text(s.sosCancel),
                ),
              ),
              const SizedBox(height: JSpace.sm),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: _launch,
                child: Text(s.sosSendNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
