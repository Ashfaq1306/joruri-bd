enum SosMessageLanguage {
  en,
  bn;

  static SosMessageLanguage parse(Object? value) =>
      value == 'bn' ? SosMessageLanguage.bn : SosMessageLanguage.en;
}

/// A position fix used in an SOS message.
class SosLocation {
  const SosLocation({
    required this.latitude,
    required this.longitude,
    required this.fixTime,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime fixTime;
  final double? accuracyMeters;

  /// Plain text link: works even when the sender is offline, because the
  /// receiver opens it on their own phone.
  String get mapLink =>
      'https://maps.google.com/?q=${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';

  String get coordinates =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

/// Builds the SOS text message.
///
/// English is the default because Bangla SMS uses 70-character segments
/// instead of 160, so long Bangla messages can arrive split or cost more.
abstract final class SosMessageBuilder {
  static const maxExtraLineLength = 100;

  /// A location older than this gets its own time stamp in the message.
  static const staleAfter = Duration(minutes: 2);

  static String build({
    required SosMessageLanguage language,
    required DateTime now,
    SosLocation? location,
    String extraLine = '',
  }) {
    final en = language == SosMessageLanguage.en;
    final lines = <String>[
      en
          ? 'EMERGENCY - I may be in danger and need help.'
          : 'জরুরি - আমি বিপদে থাকতে পারি, সাহায্য দরকার।',
    ];

    final extra = extraLine.trim();
    if (extra.isNotEmpty) {
      lines.add(extra.length > maxExtraLineLength
          ? extra.substring(0, maxExtraLineLength)
          : extra);
    }

    if (location != null) {
      lines.add('${en ? 'Location' : 'অবস্থান'}: ${location.mapLink}');
      final accuracy = location.accuracyMeters;
      if (accuracy != null && accuracy > 0) {
        lines.add(en
            ? 'Accuracy: about ${accuracy.round()} m'
            : 'নির্ভুলতা: প্রায় ${accuracy.round()} মিটার');
      }
      if (now.difference(location.fixTime) > staleAfter) {
        lines.add(en
            ? 'Location from: ${formatTime(location.fixTime)}'
            : 'অবস্থানের সময়: ${formatTime(location.fixTime)}');
      }
    } else {
      lines.add(en
          ? 'Location: not available (GPS off or no signal)'
          : 'অবস্থান: পাওয়া যায়নি (জিপিএস বন্ধ বা সিগন্যাল নেই)');
    }

    lines.add('${en ? 'Time' : 'সময়'}: ${formatTime(now)}');
    lines.add(en ? '- sent by Joruri BD' : '- জরুরি বিডি থেকে পাঠানো');
    return lines.join('\n');
  }

  /// dd/MM/yyyy HH:mm, readable in both languages without a locale library.
  static String formatTime(DateTime t) =>
      '${_two(t.day)}/${_two(t.month)}/${t.year} ${_two(t.hour)}:${_two(t.minute)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
