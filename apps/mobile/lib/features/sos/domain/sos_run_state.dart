import 'package:joruri_core/joruri_core.dart';

enum LocationOutcome { pending, found, notFound, permissionDenied, serviceOff, disabledInSettings }

enum MessageOutcome { pending, opened, failed, noContacts }

enum CallOutcome { pending, waitingForReturn, started, failed, notReturned }

/// What has happened so far in one SOS run. The status screen draws this.
class SosRunState {
  const SosRunState({
    this.running = false,
    this.location,
    this.locationOutcome = LocationOutcome.pending,
    this.messageOutcome = MessageOutcome.pending,
    this.callOutcome = CallOutcome.pending,
    this.callTarget = '',
    this.message = '',
  });

  final bool running;
  final SosLocation? location;
  final LocationOutcome locationOutcome;
  final MessageOutcome messageOutcome;
  final CallOutcome callOutcome;

  /// Contact name, or 999 when no contact is saved.
  final String callTarget;
  final String message;

  SosRunState copyWith({
    bool? running,
    SosLocation? location,
    LocationOutcome? locationOutcome,
    MessageOutcome? messageOutcome,
    CallOutcome? callOutcome,
    String? callTarget,
    String? message,
  }) {
    return SosRunState(
      running: running ?? this.running,
      location: location ?? this.location,
      locationOutcome: locationOutcome ?? this.locationOutcome,
      messageOutcome: messageOutcome ?? this.messageOutcome,
      callOutcome: callOutcome ?? this.callOutcome,
      callTarget: callTarget ?? this.callTarget,
      message: message ?? this.message,
    );
  }
}
