import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:joruri_bd/core/logging/app_logger.dart';

/// Opens the phone's SMS app with recipients and text filled in.
///
/// The person taps Send. Silent sending on Android needs Google Play's
/// SEND_SMS exception (applied for before release, see README); iOS never
/// allows it. This path works everywhere and needs no special permission.
class SmsService {
  Future<bool> compose(List<String> recipients, String body) async {
    if (recipients.isEmpty) return false;
    try {
      return await launchUrl(await _uri(recipients, body));
    } catch (e, s) {
      AppLogger.error('SMS compose failed', e, s);
      return false;
    }
  }

  Future<Uri> _uri(List<String> recipients, String body) async {
    final text = Uri.encodeComponent(body);
    if (Platform.isIOS) {
      if (recipients.length == 1) return Uri.parse('sms:${recipients.first}&body=$text');
      final addresses = recipients.map(Uri.encodeComponent).join(',');
      return Uri.parse('sms:/open?addresses=$addresses&body=$text');
    }
    final separator = await _androidSeparator();
    return Uri.parse('sms:${recipients.join(separator)}?body=$text');
  }

  /// Samsung Messages expects commas between recipients; most others semicolons.
  Future<String> _androidSeparator() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.manufacturer.toLowerCase() == 'samsung' ? ',' : ';';
    } catch (_) {
      return ';';
    }
  }
}
