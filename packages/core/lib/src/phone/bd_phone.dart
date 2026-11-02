/// Phone number helpers for Bangladesh.
abstract final class BdPhone {
  static final _mobile = RegExp(r'^01[3-9]\d{8}$');

  /// Keeps digits and a leading +. Converts Bangla digits (০-৯) to ASCII,
  /// because many people type numbers on a Bangla keyboard.
  static String clean(String input) {
    final out = StringBuffer();
    for (final unit in input.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        out.writeCharCode(unit);
      } else if (unit >= 0x09E6 && unit <= 0x09EF) {
        out.writeCharCode(0x30 + unit - 0x09E6);
      } else if (unit == 0x2B && out.isEmpty) {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }

  /// Returns +8801XXXXXXXXX for a valid Bangladeshi mobile number, else null.
  static String? normalizeMobile(String input) {
    var digits = clean(input);
    if (digits.startsWith('+880')) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('880')) {
      digits = '0${digits.substring(3)}';
    }
    if (!_mobile.hasMatch(digits)) return null;
    return '+88$digits';
  }

  /// Normalizes any number a person may save as an emergency contact.
  /// Bangladeshi mobiles become +880...; landlines and foreign numbers are
  /// kept as digits when they have 6 to 15 of them.
  static String? normalizeContact(String input) {
    final mobile = normalizeMobile(input);
    if (mobile != null) return mobile;
    final digits = clean(input);
    final count = digits.replaceAll('+', '').length;
    if (count < 6 || count > 15) return null;
    return digits;
  }

  /// Formats +8801712345678 as 01712-345678 for display.
  static String display(String normalized) {
    if (normalized.startsWith('+880') && normalized.length == 14) {
      final local = '0${normalized.substring(4)}';
      return '${local.substring(0, 5)}-${local.substring(5)}';
    }
    return normalized;
  }
}
