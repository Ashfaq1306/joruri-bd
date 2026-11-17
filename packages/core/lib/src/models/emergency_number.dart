import '../localized_text.dart';
import 'verification.dart';

enum NumberCategory {
  national,
  police,
  fire,
  ambulance,
  health,
  womenChildren,
  government,
  disaster;

  static NumberCategory parse(Object? value) => NumberCategory.values
      .firstWhere((c) => c.name == value, orElse: () => NumberCategory.government);
}

class EmergencyNumber {
  const EmergencyNumber({
    required this.id,
    required this.number,
    required this.category,
    required this.name,
    required this.description,
    required this.verification,
    this.alsoCovers = const [],
    this.districtId,
    this.address,
    this.otherNumbers = const [],
  });

  factory EmergencyNumber.fromJson(Map<String, dynamic> json) => EmergencyNumber(
        id: json['id'] as String,
        number: json['number'] as String,
        category: NumberCategory.parse(json['category']),
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        verification: Verification.fromJson(json['verification']),
        alsoCovers: ((json['alsoCovers'] as List?) ?? const [])
            .map(NumberCategory.parse)
            .toList(growable: false),
        // The admin website saves "" for "whole country".
        districtId: switch (json['districtId']) { final String d when d.isNotEmpty => d, _ => null },
        address: _address(json['address']),
        otherNumbers: ((json['otherNumbers'] as List?) ?? const []).whereType<String>().toList(growable: false),
      );

  final String id;

  /// Dialable digits, ASCII only.
  final String number;
  final NumberCategory category;
  final LocalizedText name;
  final LocalizedText description;
  final Verification verification;

  /// Other categories this number also serves (999 covers police, fire and ambulance).
  final List<NumberCategory> alsoCovers;

  /// Set for a local service (an ambulance in one city); null for national numbers.
  final String? districtId;
  final LocalizedText? address;

  /// More numbers for the same service, dialable digits.
  final List<String> otherNumbers;

  bool get isLocal => districtId != null;

  static LocalizedText? _address(Object? json) {
    if (json == null) return null;
    final a = LocalizedText.fromJson(json);
    return a.resolve('en').trim().isEmpty && a.resolve('bn').trim().isEmpty ? null : a;
  }

  bool serves(NumberCategory c) => category == c || alsoCovers.contains(c);
}
