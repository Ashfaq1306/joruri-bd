import '../localized_text.dart';

enum GuideKind {
  firstAid,
  disaster;

  static GuideKind parse(Object? value) =>
      value == 'disaster' ? GuideKind.disaster : GuideKind.firstAid;
}

enum ReviewStatus {
  /// Reviewed and signed off by a clinician or the relevant authority.
  approved,

  /// Written but not yet reviewed. Shown only with a warning banner.
  draft,

  /// No content yet.
  pending;

  static ReviewStatus parse(Object? value) => ReviewStatus.values
      .firstWhere((s) => s.name == value, orElse: () => ReviewStatus.pending);
}

/// One first-aid or disaster guide, with the four sections the brief requires.
class Guide {
  const Guide({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.reviewStatus,
    this.doNow = const LocalizedList(),
    this.doNot = const LocalizedList(),
    this.getHelp = const LocalizedList(),
    this.whoToContact = const LocalizedText(en: '', bn: ''),
    this.callNumbers = const [],
    this.sources = const [],
  });

  factory Guide.fromJson(Map<String, dynamic> json) => Guide(
        id: json['id'] as String,
        kind: GuideKind.parse(json['kind']),
        icon: (json['icon'] as String?) ?? '',
        title: LocalizedText.fromJson(json['title']),
        reviewStatus: ReviewStatus.parse(json['reviewStatus']),
        doNow: LocalizedList.fromJson(json['doNow']),
        doNot: LocalizedList.fromJson(json['doNot']),
        getHelp: LocalizedList.fromJson(json['getHelp']),
        whoToContact: LocalizedText.fromJson(json['whoToContact']),
        callNumbers: ((json['callNumbers'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
        sources: ((json['sources'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  final String id;
  final GuideKind kind;

  /// Icon key understood by the app (kept as text so content stays UI-free).
  final String icon;
  final LocalizedText title;
  final ReviewStatus reviewStatus;
  final LocalizedList doNow;
  final LocalizedList doNot;
  final LocalizedList getHelp;
  final LocalizedText whoToContact;
  final List<String> callNumbers;
  final List<String> sources;

  bool get hasContent => !doNow.isEmpty;
}
