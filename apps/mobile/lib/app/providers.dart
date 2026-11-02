import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:joruri_bd/core/platform/location_service.dart';
import 'package:joruri_bd/core/platform/phone_service.dart';
import 'package:joruri_bd/core/platform/sms_service.dart';

/// Replaced in main() with the opened instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final phoneServiceProvider = Provider<PhoneService>((ref) => PhoneService());
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());
