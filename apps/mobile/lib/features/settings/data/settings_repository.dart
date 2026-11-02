import 'package:flutter/material.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/features/settings/domain/app_settings.dart';

/// Reads and writes settings in the app's private storage.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _language = 'settings.language';
  static const _theme = 'settings.theme';
  static const _easyMode = 'settings.easyMode';
  static const _onboardingDone = 'settings.onboardingDone';
  static const _sosMode = 'settings.sosMode';
  static const _countdown = 'settings.countdownSeconds';
  static const _smsLanguage = 'settings.smsLanguage';
  static const _includeLocation = 'settings.includeLocation';
  static const _extraLine = 'settings.extraLine';

  AppSettings load() {
    final countdown = _prefs.getInt(_countdown) ?? 3;
    return AppSettings(
      languageCode: _prefs.getString(_language),
      themeMode: _pick(ThemeMode.values, _prefs.getString(_theme), ThemeMode.system),
      easyMode: _prefs.getBool(_easyMode) ?? false,
      onboardingDone: _prefs.getBool(_onboardingDone) ?? false,
      sosMode: _pick(SosMode.values, _prefs.getString(_sosMode), SosMode.countdown),
      countdownSeconds: countdown < 1 || countdown > 10 ? 3 : countdown,
      smsLanguage: SosMessageLanguage.parse(_prefs.getString(_smsLanguage)),
      includeLocation: _prefs.getBool(_includeLocation) ?? true,
      extraLine: _prefs.getString(_extraLine) ?? '',
    );
  }

  Future<void> save(AppSettings s) async {
    final language = s.languageCode;
    if (language != null) await _prefs.setString(_language, language);
    await _prefs.setString(_theme, s.themeMode.name);
    await _prefs.setBool(_easyMode, s.easyMode);
    await _prefs.setBool(_onboardingDone, s.onboardingDone);
    await _prefs.setString(_sosMode, s.sosMode.name);
    await _prefs.setInt(_countdown, s.countdownSeconds);
    await _prefs.setString(_smsLanguage, s.smsLanguage.name);
    await _prefs.setBool(_includeLocation, s.includeLocation);
    await _prefs.setString(_extraLine, s.extraLine);
  }

  static T _pick<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
