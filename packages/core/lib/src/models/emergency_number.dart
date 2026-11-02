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

  bool serves(NumberCategory c) => category == c || alsoCovers.contains(c);
}
