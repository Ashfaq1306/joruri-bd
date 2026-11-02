import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';
import 'package:joruri_bd/features/profile/domain/user_profile.dart';

/// Keeps the profile in the app's private storage on this phone.
class ProfileRepository {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'profile.v1';

  UserProfile? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.error('Saved profile could not be read', e, s);
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
