import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/app/providers.dart';
import 'package:joruri_bd/core/config/app_config.dart';
import 'package:joruri_bd/core/platform/location_service.dart';
import 'package:joruri_bd/features/contacts/presentation/contacts_controller.dart';
import 'package:joruri_bd/features/settings/presentation/settings_controller.dart';
import 'package:joruri_bd/features/sos/domain/sos_run_state.dart';

final sosControllerProvider = NotifierProvider<SosController, SosRunState>(SosController.new);

/// Runs SOS: location → text to all contacts → call the first contact.
///
/// The text goes first because once a call starts the app is in the
/// background, and iOS cannot show the SMS screen during a call. Every
/// step degrades instead of stopping: a missing permission, contact or GPS
/// fix changes how a step runs, never whether SOS continues.
class SosController extends Notifier<SosRunState> {
  _ReturnWaiter? _waiter;
  bool _cancelled = false;

  @override
  SosRunState build() {
    ref.onDispose(() => _waiter?.dispose());
    return const SosRunState();
  }

  Future<void> start() async {
    if (state.running) return;
    _cancelled = false;
    state = const SosRunState(running: true);

    final settings = ref.read(settingsProvider);
    final contacts = ref.read(contactsProvider);

    // 1. Location
    SosLocation? location;
    if (settings.includeLocation) {
      final result = await ref
          .read(locationServiceProvider)
          .current(timeout: AppConfig.freshLocationTimeout);
      if (_cancelled) return;
      location = result.location;
      state = state.copyWith(location: location, locationOutcome: _outcomeOf(result));
    } else {
      state = state.copyWith(locationOutcome: LocationOutcome.disabledInSettings);
    }

    // 2. Text message
    final message = SosMessageBuilder.build(
      language: settings.smsLanguage,
      now: DateTime.now(),
      location: location,
      extraLine: settings.extraLine,
    );
    state = state.copyWith(message: message);

    if (contacts.isEmpty) {
      state = state.copyWith(messageOutcome: MessageOutcome.noContacts);
    } else {
      state = state.copyWith(callTarget: contacts.first.name);
      final waiter = _waiter = _ReturnWaiter()..listen();
      final opened = await ref
          .read(smsServiceProvider)
          .compose(contacts.map((c) => c.phone).toList(), message);
      if (_cancelled) return;
      state = state.copyWith(messageOutcome: opened ? MessageOutcome.opened : MessageOutcome.failed);

      if (opened) {
        // Wait until the person comes back from the SMS app, so the call
        // does not cover the Send button.
        state = state.copyWith(callOutcome: CallOutcome.waitingForReturn);
        final cameBack = await waiter.wait(AppConfig.waitForReturnFromSms);
        waiter.dispose();
        _waiter = null;
        if (_cancelled) return;
        if (!cameBack) {
          state = state.copyWith(callOutcome: CallOutcome.notReturned, running: false);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (_cancelled) return;
      } else {
        waiter.dispose();
        _waiter = null;
      }
    }

    // 3. Call
    await _placeCall(contacts);
    if (_cancelled) return;
    state = state.copyWith(running: false);
  }

  /// Skips the wait and calls straight away.
  void callNow() => _waiter?.release(true);

  Future<void> callAgain() => _placeCall(ref.read(contactsProvider));

  /// Takes a fresh fix if possible and opens the SMS app again.
  Future<void> resendMessage() async {
    final contacts = ref.read(contactsProvider);
    if (contacts.isEmpty) return;
    final settings = ref.read(settingsProvider);

    var location = state.location;
    if (settings.includeLocation) {
      final fresh = await ref
          .read(locationServiceProvider)
          .current(timeout: AppConfig.freshLocationTimeout);
      if (fresh.location != null) {
        location = fresh.location;
        state = state.copyWith(location: location, locationOutcome: LocationOutcome.found);
      }
    }
    final message = SosMessageBuilder.build(
      language: settings.smsLanguage,
      now: DateTime.now(),
      location: location,
      extraLine: settings.extraLine,
    );
    final opened = await ref
        .read(smsServiceProvider)
        .compose(contacts.map((c) => c.phone).toList(), message);
    state = state.copyWith(
      message: message,
      messageOutcome: opened ? MessageOutcome.opened : MessageOutcome.failed,
    );
  }

  /// "I am safe": stops anything still pending, including the planned call.
  void cancel() {
    _cancelled = true;
    _waiter?.release(false);
    _waiter?.dispose();
    _waiter = null;
    state = const SosRunState();
  }

  Future<void> _placeCall(List<EmergencyContact> contacts) async {
    final phone = ref.read(phoneServiceProvider);
    if (contacts.isEmpty) {
      final ok = await phone.dial(AppConfig.nationalEmergencyNumber);
      state = state.copyWith(
        callTarget: AppConfig.nationalEmergencyNumber,
        callOutcome: ok ? CallOutcome.started : CallOutcome.failed,
      );
      return;
    }
    final primary = contacts.first;
    final ok = await phone.callDirect(primary.phone);
    state = state.copyWith(
      callTarget: primary.name,
      callOutcome: ok ? CallOutcome.started : CallOutcome.failed,
    );
  }

  LocationOutcome _outcomeOf(LocationResult result) {
    if (result.location != null) return LocationOutcome.found;
    return switch (result.issue) {
      LocationIssue.denied || LocationIssue.deniedForever => LocationOutcome.permissionDenied,
      LocationIssue.serviceOff => LocationOutcome.serviceOff,
      _ => LocationOutcome.notFound,
    };
  }
}

/// Completes when the person returns to the app after leaving it.
class _ReturnWaiter {
  final _completer = Completer<bool>();
  AppLifecycleListener? _listener;
  bool _left = false;

  /// Must be called before leaving the app, so no lifecycle event is missed.
  void listen() {
    _listener = AppLifecycleListener(
      onHide: () => _left = true,
      onPause: () => _left = true,
      onResume: () {
        if (_left) release(true);
      },
    );
  }

  Future<bool> wait(Duration timeout) =>
      _completer.future.timeout(timeout, onTimeout: () => false);

  void release(bool value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  void dispose() {
    _listener?.dispose();
    _listener = null;
  }
}
