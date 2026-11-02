import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

/// Real reachability, not just "Wi-Fi is connected".
///
/// Tries DNS for two well-known hosts, then a direct connection to public
/// DNS servers, which still works when a network's DNS is slow or blocked.
/// Re-checks on every network change and every 30 seconds, so one slow
/// check at start-up can never leave "Offline" stuck on screen.
/// Until the first check finishes the provider is loading and the pill
/// shows nothing (emergency features never depend on this anyway).
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final controller = StreamController<NetworkStatus>();
  NetworkStatus? last;
  var checking = false;

  void emit(NetworkStatus status) {
    if (status == last || controller.isClosed) return;
    last = status;
    controller.add(status);
  }

  Future<void> check() async {
    if (checking) return;
    checking = true;
    try {
      emit(await probeInternet());
    } finally {
      checking = false;
    }
  }

  StreamSubscription<List<ConnectivityResult>>? changes;
  try {
    changes = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (results.isNotEmpty && results.every((r) => r == ConnectivityResult.none)) {
          emit(NetworkStatus.offline); // airplane mode / no network: say so at once
        } else {
          check();
        }
      },
      onError: (_) {},
    );
  } catch (_) {
    // Plugin unavailable (tests): the periodic check still works.
  }
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  check();

  ref.onDispose(() {
    changes?.cancel();
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

/// True internet test. Exposed for tests.
Future<NetworkStatus> probeInternet() async {
  for (final host in const ['google.com', 'cloudflare.com']) {
    try {
      final found = await InternetAddress.lookup(host).timeout(const Duration(seconds: 4));
      if (found.isNotEmpty && found.first.rawAddress.isNotEmpty) return NetworkStatus.online;
    } catch (_) {}
  }
  for (final ip in const ['1.1.1.1', '8.8.8.8']) {
    try {
      final socket = await Socket.connect(ip, 53, timeout: const Duration(seconds: 3));
      socket.destroy();
      return NetworkStatus.online;
    } catch (_) {}
  }
  return NetworkStatus.offline;
}
