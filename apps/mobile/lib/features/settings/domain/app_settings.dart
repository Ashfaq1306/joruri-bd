import 'package:flutter/material.dart';
import 'package:joruri_core/joruri_core.dart';

enum SosMode { countdown, instant }

/// Everything the person chose. Stored on the phone only.
class AppSettings {
  const AppSettings({
    this.languageCode,
    this.themeMode = ThemeMode.system,
    this.easyMode = false,
    this.onboardingDone = false,
    this.sosMode = SosMode.countdown,
    this.countdownSeconds = 3,
    this.smsLanguage = SosMessageLanguage.en,
    this.includeLocation = true,
    this.extraLine = '',
  });

  /// null until the person picks one; the phone's language is used meanwhile.
  final String? languageCode;
  final ThemeMode themeMode;
  final bool easyMode;
  final bool onboardingDone;
  final SosMode sosMode;
  final int countdownSeconds;
  final SosMessageLanguage smsLanguage;
  final bool includeLocation;
  final String extraLine;

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    bool? easyMode,
    bool? onboardingDone,
    SosMode? sosMode,
    int? countdownSeconds,
    SosMessageLanguage? smsLanguage,
    bool? includeLocation,
    String? extraLine,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      easyMode: easyMode ?? this.easyMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      sosMode: sosMode ?? this.sosMode,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      smsLanguage: smsLanguage ?? this.smsLanguage,
      includeLocation: includeLocation ?? this.includeLocation,
      extraLine: extraLine ?? this.extraLine,
    );
  }
}
