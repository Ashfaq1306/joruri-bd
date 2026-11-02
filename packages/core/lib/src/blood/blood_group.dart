/// The eight ABO/Rh blood groups.
enum BloodGroup {
  aPos('A+'),
  aNeg('A-'),
  bPos('B+'),
  bNeg('B-'),
  abPos('AB+'),
  abNeg('AB-'),
  oPos('O+'),
  oNeg('O-');

  const BloodGroup(this.label);

  final String label;

  /// Accepts what people type in forms and spreadsheets:
  /// "A+", "a +", "A+ve", "O-ve", "AB positive", "B neg", "O−" (Unicode minus).
  static BloodGroup? parse(String? input) {
    if (input == null) return null;
    var s = input.toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceAll('\u2212', '-');
    s = s
        .replaceAll('POSITIVE', '+')
        .replaceAll('NEGATIVE', '-')
        .replaceAll('POS', '+')
        .replaceAll('NEG', '-')
        .replaceAll('VE', '');
    for (final g in BloodGroup.values) {
      if (g.label == s) return g;
    }
    return null;
  }

  static BloodGroup? fromName(String? name) {
    for (final g in BloodGroup.values) {
      if (g.name == name) return g;
    }
    return null;
  }

  /// Donor groups whose red cells a patient of this group can usually receive
  /// (standard ABO/Rh table). A guide only: the blood bank must confirm with
  /// a cross-match before any transfusion.
  List<BloodGroup> get canReceiveFrom => switch (this) {
        BloodGroup.oNeg => const [BloodGroup.oNeg],
        BloodGroup.oPos => const [BloodGroup.oPos, BloodGroup.oNeg],
        BloodGroup.aNeg => const [BloodGroup.aNeg, BloodGroup.oNeg],
        BloodGroup.aPos => const [BloodGroup.aPos, BloodGroup.aNeg, BloodGroup.oPos, BloodGroup.oNeg],
        BloodGroup.bNeg => const [BloodGroup.bNeg, BloodGroup.oNeg],
        BloodGroup.bPos => const [BloodGroup.bPos, BloodGroup.bNeg, BloodGroup.oPos, BloodGroup.oNeg],
        BloodGroup.abNeg => const [BloodGroup.abNeg, BloodGroup.aNeg, BloodGroup.bNeg, BloodGroup.oNeg],
        BloodGroup.abPos => BloodGroup.values,
      };
}
