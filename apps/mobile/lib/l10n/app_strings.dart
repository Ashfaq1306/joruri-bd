import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_bn.dart';
import 'strings_en.dart';

/// Every user-facing string in the app.
///
/// Typed Dart classes instead of ARB files: if a Bangla string is missing,
/// the app does not compile, so a blank button can never ship. Admin-managed
/// content (numbers, guides) carries its own bn/en text in the seed data.
abstract class AppStrings {
  const AppStrings();

  static const supportedLocales = [Locale('bn'), Locale('en')];
  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? const StringsEn();

  String get languageCode;

  // General
  String get appName;
  String get tagline;
  String get welcome;
  String get chooseLanguage;
  String get chooseTheme;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get next;
  String get back;
  String get skip;
  String get finish;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get copy;
  String get share;
  String get copied;
  String get close;
  String get openSettings;
  String get retry;
  String get genericError;
  String get notYetVerified;
  String get sourceLabel;
  String checkedOn(String date);

  // Onboarding
  String get contactsStepTitle;
  String get contactsStepBody;
  String get sosStepTitle;
  String get sosModeCountdown;
  String get sosModeCountdownBody;
  String get sosModeInstant;
  String get sosModeInstantBody;
  String get permissionsTitle;
  String get permissionsBody;
  String get allowLocation;
  String get allowCalls;
  String get allowed;
  String get getStarted;

  // Contacts
  String get emergencyContacts;
  String get contactsExplainer;
  String get contactName;
  String get contactPhone;
  String get addContact;
  String get editContact;
  String get primaryContact;
  String get makePrimary;
  String get invalidPhone;
  String get nameRequired;
  String get maxContactsReached;
  String get noContactsTitle;
  String get noContactsBody;
  String get removeContactQuestion;

  // Home and navigation
  String get sosHint;
  String get tileBlood;
  String get tileAmbulance;
  String get tileHospitals;
  String get tilePolice;
  String get tileFire;
  String get tileDisaster;
  String get tileFirstAid;
  String get tileToolkit;
  String get roadAccident;
  String get roadAccidentHint;
  String get online;
  String get offline;
  String get call999;
  String get callMyContact;
  String get navHome;
  String get navGuides;
  String get navSettings;

  // SOS
  String get sosSendingIn;
  String get sosCancel;
  String get sosSendNow;
  String get sosStatusTitle;
  String get sosStepLocation;
  String get sosStepMessage;
  String get sosStepCall;
  String get sosLocating;
  String get sosLocationFound;
  String get sosLocationNotFound;
  String get sosLocationDenied;
  String get sosLocationServiceOff;
  String get sosLocationDisabled;
  String get sosPreparingMessage;
  String get sosMessageOpened;
  String get sosMessageFailed;
  String get sosNoContacts;
  String sosWaitingToCall(String name);
  String get sosCallNow;
  String sosCalling(String name);
  String get sosCallFailed;
  String get sosNotCalled;
  String get sosSendAgain;
  String get sosCallAgain;
  String get sosShareOther;
  String get sosSafeClose;
  String get sosReadCoordinates;

  // Location
  String get myLocation;
  String get locationReason;
  String get latitude;
  String get longitude;
  String accuracyMeters(int meters);
  String locationTime(String time);
  String get openInMaps;
  String get textMyContacts;
  String get refresh;
  String myLocationMessage(String link);
  String get copyCoordinates;
  String get locationDeniedForever;

  // Emergency numbers
  String get emergencyNumbers;
  String callNumber(String number);
  String get localNumbersPending;
  String get noNumbers;

  // Guides
  String get guides;
  String get whatToDoNow;
  String get whatNotToDo;
  String get whenToGetHelp;
  String get whoToContact;
  String get draftBanner;
  String get guidePending;
  String get draftLabel;
  String get pendingLabel;
  String get sources;

  // Toolkit
  String get flashlight;
  String get turnOn;
  String get turnOff;
  String get flashlightUnavailable;
  String get siren;
  String get sirenHint;
  String get compass;
  String get compassUnavailable;
  String get compassHint;

  /// N, NE, E, SE, S, SW, W, NW.
  List<String> get directions;
  String get gpsCoordinates;
  String get battery;
  String batteryLevel(int percent);
  String get charging;
  String get lowBatteryTip;

  // Accident
  String get accidentSafetyNote;
  String get ambulance999;
  String get police999;
  String get nearestHospitals;

  // Coming soon
  String get bloodComingSoonTitle;
  String get bloodComingSoonBody;
  String get hospitalsComingSoonTitle;
  String get hospitalsComingSoonBody;
  String get searchHospitalsInMaps;
  String get needsInternet;

  // Settings
  String get settings;
  String get language;
  String get theme;
  String get easyMode;
  String get easyModeBody;
  String get sosSettings;
  String get sosMode;
  String get countdownLength;
  String seconds(int n);
  String get smsLanguage;
  String get smsLanguageHint;
  String get includeLocation;
  String get includeLocationBody;
  String get extraLine;
  String get extraLineHint;
  String get previewMessage;
  String get exampleMessage;
  String get permissions;
  String get privacy;
  String get privacyBody;
  String get deleteLocalData;
  String get deleteLocalDataBody;
  String get deleted;
  String get about;
  String get version;

  // Blood
  String get needBlood;
  String get chooseBloodGroup;
  String get bloodGroupHint;
  String donorsTitle(String group);
  String get division;
  String get district;
  String get allDivisions;
  String get allDistricts;
  String get searchArea;
  String get includeCompatible;
  String get availableOnly;
  String donorsFound(int n);
  String get noDonorsTitle;
  String get noDonorsBody;
  String get bloodDisclaimer;
  String lastDonated(String date);
  String get availableNow;
  String get notAvailableNow;
  String get verifiedDonor;
  String get demoDonor;
  String get compatibleBadge;
  String get callShort;
  String get filters;

  // Hospitals and pharmacies
  String get tilePharmacy;
  String get tabHospitalList;
  String get tabTestsPrices;
  String get searchTest;
  String get testSearchHint;
  String hospitalsFound(int n);
  String testResults(int n);
  String get noHospitals;
  String get noTestResults;
  String get emergencyLine;
  String get serviceEmergency;
  String get serviceBloodBank;
  String get serviceIcu;
  String get open24h;
  String get testsAndPrices;
  String pricesChecked(String date);
  String get priceUnknown;
  String taka(String amount);
  String get details;
  String get pharmacyHint;
  String get only24h;
  String pharmaciesFound(int n);
  String get noPharmacies;
  String get searchPharmaciesInMaps;
  String get demoPlace;
  String get searchTestInHospital;
  String get tabPharmacies;
  String get tabMedicinePrices;
  String get chooseDistrictForPharmacies;
  String get searchPharmacyHint;
  String get onlyWithPhone;
  String licenceValidUntil(String date);
  String licenceExpired(String date);
  String get pharmacyDirections;
  String get pharmacySourceNote;
  String get searchMedicine;
  String get medicineSearchHint;
  String medicinesFound(int n);
  String get noMedicineFound;
  String get pricePerUnit;
  String get noPublishedPrice;
  String get sameMedicineOtherBrands;
  String get cheapest;
  String medicinePriceNote(String date);
  String get medicineCompany;
  String get medicineGeneric;
  String get medicinePack;
  String get medicineDar;

  // Account and profile
  String get brandLine;
  String get createAccount;
  String get accountWhy;
  String get fullName;
  String get mobileNumber;
  String get yourBloodGroup;
  String get yourLocation;
  String get wantDonate;
  String get availableToggle;
  String get consentShow;
  String get saveAccount;
  String get skipAccount;
  String get errName;
  String get errGroup;
  String get errDistrict;
  String get errConsent;
  String get myProfile;
  String get editProfile;
  String get youBadge;
  String get listedAsDonor;
  String get notListed;
  String get noProfileYet;
  String get profileSaved;
  String get requiredMark;

  // Online: verification and live donors
  String get verifyTitle;
  String get verifyBody;
  String get sendCode;
  String codeSentTo(String phone);
  String get enterCode;
  String get confirmCode;
  String get resendCode;
  String get later;
  String get verifiedOk;
  String get verifiedVisible;
  String get notVerifiedHidden;
  String get verifyMyNumber;
  String get signOut;
  String get wrongCode;
  String get tooManyTries;
  String get onlineNotReady;
  String get liveListTitle;
  String get liveListBody;
  String get liveListOn;
  String get needInternetForCode;
  String get createProfileFirst;
  String get phoneChangedReverify;

  // Google sign-in and online sync status
  String get signInTitle;
  String get signInBody;
  String get signInWithGoogle;
  String get signInFailed;
  String get signInNotAvailable;
  String signedInAs(String who);
  String get phoneSelfDeclared;
  String get syncSavedLocal;
  String get syncSignedOut;
  String get syncSyncing;
  String get syncDone;
  String get syncWaiting;
  String get syncNotAllowed;
  String get syncFailed;
  String get syncRetry;
  String get liveListUnavailable;
  String get liveListBodyGoogle;

  // Sign-in with a link sent by e-mail (free; SMS codes need a paid plan)
  String get orWord;
  String get signInWithEmail;
  String get sendSignInLink;
  String get sendAgain;
  String signInLinkSent(String email);
  String get pasteSignInLink;
  String get signInLinkLabel;
  String get pasteWord;
  String get finishSignIn;
  String get finishSignInBody;
  String get emailInvalid;
  String get signInLinkInvalid;
  String get signInEmailMismatch;
  String get emailDailyLimit;

  // App updates and announcements (managed on the admin website)
  String get updateAvailable;
  String get updateRequired;
  String updateBody(String version);
  String get updateRequiredBody;
  String get updateDownload;
  String get whatsNew;
  String get checkForUpdates;
  String get upToDate;
  String get checking;
  String get updatesCheckFailed;
  String get downloadStarted;
  String updateDownloading(int? percent);
  String get updateReady;
  String get updateInstall;
  String get updateAllowInstall;
  String get updateDownloadFailed;
  String get updateInBrowser;
  String get openLink;

  // Hospital directory (DGHS data)
  String get searchNameOrArea;
  String get filterGovernment;
  String get filterPrivate;
  String beds(int n);
  String get otherNumbers;
  String get noPhoneListed;
  String get govFeeNote;
  String get emailLabel;
  String get websiteLabel;
  String get directionsLabel;
  String showingFirst(int shown, int total);

  // Police stations
  String get policeStations;
  String get findLocalPolice;
  String findLocalPoliceSub(int n);
  String get searchPoliceHint;
  String policeStationsFound(int n);
  String get officerInCharge;
  String get chooseDistrictForPolice;
  String get noPoliceStations;
  String get policeSourceNote;
  String get policeNumberTip;

  // Fire stations (Fire Service and Civil Defence)
  String get fireStations;
  String get findLocalFire;
  String findLocalFireSub(int n);
  String get searchFireHint;
  String fireStationsFound(int n);
  String get chooseDistrictForFire;
  String get noFireStations;
  String get fireSourceNote;
  String get fireNumberTip;
  String get stationNumber;
  String get officeNumber;
  String get numberBeingChecked;
  String get bloodBanksNearby;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'bn' || locale.languageCode == 'en';

  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture<AppStrings>(
        locale.languageCode == 'bn' ? const StringsBn() : const StringsEn(),
      );

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
