import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the app theme. Easy Mode raises every button to at least 72 dp.
///
/// Text uses Hind Siliguri (Bangla + Latin) once `dart run tool/get_fonts.dart`
/// has bundled it; until then Flutter quietly falls back to the phone's fonts.
ThemeData buildJoruriTheme({required Brightness brightness, bool easyMode = false}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: JColors.flagGreen,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF6FD3AE) : JColors.flagGreen,
    surface: dark ? JColors.night : JColors.paper,
    error: JColors.sos,
  );

  final buttonHeight = easyMode ? JSize.easyTouch : 56.0;
  final buttonText = TextStyle(fontSize: easyMode ? 20 : 17, fontWeight: FontWeight.w600);
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Hind Siliguri',
    fontFamilyFallback: const ['Noto Sans Bengali'],
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(64, buttonHeight),
        textStyle: buttonText,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(64, buttonHeight),
        textStyle: buttonText,
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(64, JSize.minTouch)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: easyMode ? 84 : 72,
      // Frosted, slightly see-through bar over the mesh background.
      backgroundColor: dark ? const Color(0xD9121E19) : const Color(0xD9FAFCFB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: dark ? JColors.flagGreenDark : const Color(0xFFCDEBDF),
    ),
  );
}
