/// Text stored in both app languages.
///
/// Falls back to the other language when one is missing, so a screen is
/// never blank because a translation was forgotten.
class LocalizedText {
  const LocalizedText({required this.en, required this.bn});

  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(
        en: (json['en'] as String?) ?? '',
        bn: (json['bn'] as String?) ?? '',
      );
    }
    return const LocalizedText(en: '', bn: '');
  }

  final String en;
  final String bn;

  bool get isEmpty => en.trim().isEmpty && bn.trim().isEmpty;

  String resolve(String languageCode) {
    final primary = languageCode == 'bn' ? bn : en;
    if (primary.trim().isNotEmpty) return primary;
    return languageCode == 'bn' ? en : bn;
  }

  Map<String, String> toJson() => {'en': en, 'bn': bn};
}

/// A list of lines in both languages, used for guide steps.
class LocalizedList {
  const LocalizedList({this.en = const [], this.bn = const []});

  factory LocalizedList.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedList(en: _strings(json['en']), bn: _strings(json['bn']));
    }
    return const LocalizedList();
  }

  final List<String> en;
  final List<String> bn;

  bool get isEmpty => en.isEmpty && bn.isEmpty;

  List<String> resolve(String languageCode) {
    final primary = languageCode == 'bn' ? bn : en;
    if (primary.isNotEmpty) return primary;
    return languageCode == 'bn' ? en : bn;
  }

  static List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
