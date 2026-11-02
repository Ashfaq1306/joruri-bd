import 'package:flutter/painting.dart';

/// Colour tokens.
///
/// The brand is the Bangladesh flag: bottle green for the app, and the red
/// disc kept for one thing only, SOS. Every colour used behind white text
/// meets WCAG AA (4.5:1).
abstract final class JColors {
  static const flagGreen = Color(0xFF006A4E);
  static const flagGreenDark = Color(0xFF00513C);

  /// Deeper than the flag red so white text on it passes 4.5:1.
  static const sos = Color(0xFFC8102E);
  static const sosPressed = Color(0xFF9E0B22);
  static const sosShadow = Color(0x66C8102E);

  /// Road-sign amber for accident mode; always paired with dark text.
  static const amber = Color(0xFFFFB300);
  static const ink = Color(0xFF14211C);

  static const paper = Color(0xFFF6F8F7);
  static const night = Color(0xFF0E1714);
  static const nightSurface = Color(0xFF17241F);

  // Category accents, used as icon discs behind white icons.
  static const blood = Color(0xFFB71C1C);
  static const ambulance = Color(0xFF00796B);
  static const hospital = Color(0xFF1565C0);
  static const police = Color(0xFF283593);
  static const fire = Color(0xFFBF360C);
  static const disaster = Color(0xFF006064);
  static const firstAid = Color(0xFF2E7D32);
  static const toolkit = Color(0xFF455A64);

  static const ok = Color(0xFF2E7D32);
  static const warning = Color(0xFFB26A00);
  static const online = Color(0xFF34C759);
  static const offline = Color(0xFFFF9500);
}

/// 4-point spacing scale.
abstract final class JSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class JSize {
  static const minTouch = 48.0;
  static const easyTouch = 72.0;
  static const sosButton = 176.0;
  static const sosButtonEasy = 224.0;
  static const tileHeight = 76.0;
  static const bigButtonHeight = 88.0;
  static const radius = 16.0;
}
