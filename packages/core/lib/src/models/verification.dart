enum VerificationStatus {
  verified,
  unverified;

  static VerificationStatus parse(Object? value) => value == 'verified'
      ? VerificationStatus.verified
      : VerificationStatus.unverified;
}

/// Where a safety-critical fact came from, and whether a person confirmed it.
class Verification {
  const Verification({
    required this.status,
    this.sourceName,
    this.sourceUrl,
    this.checkedOn,
    this.note,
  });

  factory Verification.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return Verification(
      status: VerificationStatus.parse(map['status']),
      sourceName: map['sourceName'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      checkedOn: map['checkedOn'] as String?,
      note: map['note'] as String?,
    );
  }

  final VerificationStatus status;
  final String? sourceName;
  final String? sourceUrl;

  /// ISO date (yyyy-MM-dd) of the last check.
  final String? checkedOn;
  final String? note;

  bool get isVerified => status == VerificationStatus.verified;
}
