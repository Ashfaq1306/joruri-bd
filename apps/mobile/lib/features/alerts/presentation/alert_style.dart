import 'package:flutter/material.dart';
import 'package:joruri_core/joruri_core.dart';

import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Colours, icons and words for alerts, the same on every screen.
abstract final class AlertStyle {
  static Color color(AlertLevel l) => switch (l) {
        AlertLevel.emergency => const Color(0xFFC62828),
        AlertLevel.warning => const Color(0xFFE65100),
        AlertLevel.watch => const Color(0xFFF2A900),
        AlertLevel.advisory => const Color(0xFF1565C0),
      };

  /// Text colour on top of [color].
  static Color onColor(AlertLevel l) => l == AlertLevel.watch ? const Color(0xFF14211C) : Colors.white;

  static IconData icon(Hazard h) => switch (h) {
        Hazard.cyclone => Icons.cyclone,
        Hazard.flood => Icons.flood,
        Hazard.rain => Icons.water_drop,
        Hazard.storm => Icons.thunderstorm,
        Hazard.heat => Icons.wb_sunny,
        Hazard.cold => Icons.ac_unit,
        Hazard.fog => Icons.foggy,
        Hazard.landslide => Icons.landslide,
        Hazard.earthquake => Icons.vibration,
        Hazard.tsunami => Icons.tsunami,
        Hazard.other => Icons.warning_amber_rounded,
      };

  static String hazard(AppStrings s, Hazard h) => switch (h) {
        Hazard.cyclone => s.hazardCyclone,
        Hazard.flood => s.hazardFlood,
        Hazard.rain => s.hazardRain,
        Hazard.storm => s.hazardStorm,
        Hazard.heat => s.hazardHeat,
        Hazard.cold => s.hazardCold,
        Hazard.fog => s.hazardFog,
        Hazard.landslide => s.hazardLandslide,
        Hazard.earthquake => s.hazardEarthquake,
        Hazard.tsunami => s.hazardTsunami,
        Hazard.other => s.hazardOther,
      };

  static String level(AppStrings s, AlertLevel l) => switch (l) {
        AlertLevel.emergency => s.levelEmergency,
        AlertLevel.warning => s.levelWarning,
        AlertLevel.watch => s.levelWatch,
        AlertLevel.advisory => s.levelAdvisory,
      };

  static String source(AppStrings s, String source) => switch (source) {
        AlertSource.bmd => s.sourceBmd,
        AlertSource.usgs => s.sourceUsgs,
        _ => s.sourceTeam,
      };
}

const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];

/// "14 Nov, 6:05 pm" / "১৪ নভেম্বর, সন্ধ্যা ৬:০৫", in the phone's time zone.
String formatAlertTime(DateTime t, String lang) {
  final d = t.toLocal();
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  if (lang == 'bn') {
    final part = switch (d.hour) {
      >= 4 && < 6 => 'ভোর',
      >= 6 && < 12 => 'সকাল',
      >= 12 && < 15 => 'দুপুর',
      >= 15 && < 18 => 'বিকেল',
      >= 18 && < 20 => 'সন্ধ্যা',
      _ => 'রাত',
    };
    return localizedDigits('${d.day} ${_monthsBn[d.month - 1]}, $part $h12:$mm', 'bn');
  }
  return '${d.day} ${_monthsEn[d.month - 1]}, $h12:$mm ${d.hour < 12 ? 'am' : 'pm'}';
}

/// "5 min ago", "3 h ago", or the date for older times.
String formatAgo(AppStrings s, DateTime t, DateTime now) {
  final diff = now.difference(t);
  final lang = s.languageCode;
  if (diff.inMinutes < 1) return s.justNow;
  if (diff.inMinutes < 60) return localizedDigits(s.minutesAgo(diff.inMinutes), lang);
  if (diff.inHours < 24) return localizedDigits(s.hoursAgo(diff.inHours), lang);
  return formatAlertTime(t, lang);
}
