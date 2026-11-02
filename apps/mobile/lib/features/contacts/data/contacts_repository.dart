import 'dart:convert';

import 'package:joruri_core/joruri_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

/// Emergency contacts, kept in the app's private storage on this phone.
/// Nothing is uploaded. (Cloud sync arrives with accounts, opt-in only.)
class ContactsRepository {
  ContactsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'contacts.v1';

  List<EmergencyContact> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .toList(growable: false);
    } catch (e, s) {
      AppLogger.error('Saved contacts could not be read', e, s);
      return const [];
    }
  }

  Future<void> save(List<EmergencyContact> contacts) async {
    await _prefs.setString(_key, jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }
}
