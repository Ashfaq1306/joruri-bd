/// App-wide constants. Values that admins will tune later move to remote
/// settings in Phase 4; everything here works with no network.
abstract final class AppConfig {
  /// Bangladesh National Emergency Service: police, fire service, ambulance.
  /// Toll-free call, 24 hours. Source: see assets/seed/emergency_numbers.json.
  static const nationalEmergencyNumber = '999';

  static const maxEmergencyContacts = 3;

  /// Seed data is confirmed by a person before release (README, "Release gate").
  /// Until then unverified entries are shown, always with a visible
  /// "Not yet verified" label. Set to false for the store build.
  static const showUnverifiedContent = true;

  /// Draft first-aid text is shown only with a warning banner. Set to false
  /// for the store build unless a clinician has approved every draft.
  static const showDraftGuides = true;

  /// Sample donors (numbers start with 010, which no operator uses) so the
  /// blood screens can be tried before real data is imported.
  /// Set to false for the store build.
  static const showDemoDonors = false;

  /// Sample hospitals (with test prices) and pharmacies so the screens can
  /// be tried before real data is imported. Set to false for the store build.
  static const showDemoDirectory = false;

  /// Sample hospitals (with fictional test prices) and pharmacies, so the
  /// screens can be tried before real data is imported. False for release.
  static const showDemoPlaces = false;

  static const freshLocationTimeout = Duration(seconds: 10);

  /// After the SMS app opens, SOS calls your contact when you come back.
  /// If you do not come back within this time, it does not call by surprise.
  static const waitForReturnFromSms = Duration(minutes: 3);
}
