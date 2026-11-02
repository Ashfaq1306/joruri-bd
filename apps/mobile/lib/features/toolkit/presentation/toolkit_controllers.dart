import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torch_light/torch_light.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

enum TorchState { off, on, unavailable }

/// Flashlight state lives app-wide, so it stays on while you move between screens.
final torchProvider = NotifierProvider<TorchController, TorchState>(TorchController.new);

class TorchController extends Notifier<TorchState> {
  @override
  TorchState build() => TorchState.off;

  Future<void> toggle() async {
    try {
      if (state == TorchState.on) {
        await TorchLight.disableTorch();
        state = TorchState.off;
        return;
      }
      if (!await TorchLight.isTorchAvailable()) {
        state = TorchState.unavailable;
        return;
      }
      await TorchLight.enableTorch();
      state = TorchState.on;
    } catch (e, s) {
      AppLogger.error('Flashlight failed', e, s);
      state = TorchState.unavailable;
    }
  }
}

/// Loud looping siren from a bundled sound, so it works offline.
final sirenProvider = NotifierProvider<SirenController, bool>(SirenController.new);

class SirenController extends Notifier<bool> {
  AudioPlayer? _player;

  @override
  bool build() {
    ref.onDispose(() => _player?.dispose());
    return false;
  }

  Future<void> toggle() async {
    try {
      final player = _player ??= AudioPlayer();
      if (state) {
        await player.stop();
        state = false;
        return;
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1);
      await player.play(AssetSource('sounds/siren.wav'));
      state = true;
    } catch (e, s) {
      AppLogger.error('Siren failed', e, s);
      state = false;
    }
  }
}
