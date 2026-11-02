# JORURI BD

Bangladesh emergency response companion. *Help when every second matters.*

This repository contains the app (emergency core works **fully offline and without an account**), the **admin website** (`admin/`) and the **online backend** (`firebase/`). To switch on automatic updates and live donors, follow **[SETUP_ONLINE.md](SETUP_ONLINE.md)**. Sign-in uses **Google** in the app and on the admin website (free Spark plan). `firebase.json` is **hosting-only**; the live Firestore rules stay locked and the proposal in `firebase/RULES_PROPOSAL.md` is **not deployed**. Latest changes: `CHANGES_DONOR_SYNC.md`. Until then the app runs on its built-in data.

## What works now

| Feature | Notes |
| --- | --- |
| Onboarding | Language → **account** (name, mobile, blood group, division/district, area; donor switches and consent) → theme → emergency contacts → SOS mode and permissions. The account can be skipped ("not now") so SOS works for someone who just installed the app. |
| My profile | Top of Settings: your details, whether you are in the donor list, and a switch to set your own availability. If you agreed to be listed, you appear in blood search with a "You" badge. Saved on this phone; OTP verification arrives in Phase 4. |
| Home | Gradient green panel with the Joruri logo tile, glowing SOS disc, 3×3 actions, road accident bar, online/offline pill. Frosted top and bottom bars, soft shadows, press animations, subtle mesh background (same design as the preview). |
| SOS | 3- or 5-second countdown (or instant) → GPS location → SMS app opens with all contacts and the message filled in → when you return, it calls your first contact. No contacts → dials 999. |
| SOS status | Step-by-step result, coordinates to read out, call 999, resend, share via WhatsApp etc., "I am safe" |
| Emergency contacts | Up to 3, Bangla digits accepted, first one is called |
| Emergency numbers | 999, 109, 1098, 16263, 333, each with its source |
| First aid | 17 topics; 5 have draft content (bleeding, burns, choking, electric shock, snake bite), 12 say "being written" |
| Disaster | 6 topics listed; content comes in Phase 6 |
| Toolkit | Flashlight, siren (bundled sound), compass, GPS coordinates, battery, contacts |
| Road accident mode | Six large buttons on one screen |
| Easy Mode | Very large buttons and text for older users |
| Settings | Language, theme, Easy Mode, SOS options, message preview, permissions, privacy, delete my data |
| Blood | Pick the blood group needed → every donor with that group, with their number and a Call button. Filter by division, district and area; optionally include other compatible groups. Works offline. |
| Hospitals | List by division, district and area, with services (emergency, 24 hours, blood bank, ambulance, ICU) and call buttons. **Tests & prices** tab: search a test (English or Bangla, e.g. CBC, সিবিসি) and see every hospital that does it, cheapest first. Each hospital page lists all its tests and prices. |
| Pharmacy | Pharmacies by area, 24-hour ones first, with a Call button and a Google Maps fallback. |

## Run it (first time)

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24 or newer), Android Studio for Android, and a Mac with Xcode for iOS.

```bash
cd apps/mobile

# 1. Generate the android/ and ios/ folders (your lib/ files are not touched)
flutter create . --org bd.joruri --project-name joruri_bd --platforms android,ios

# 2. Add permissions, app name and minimum Android version
dart run tool/setup.dart

# 2b. Bundle the Hind Siliguri font so the app looks like the preview
dart run tool/get_fonts.dart

# 2c. App icon from the Joruri logo
dart run flutter_launcher_icons

# 3. Download packages and run on a connected phone (release = full speed)
flutter pub get
flutter run --release
```

Run the tests:

```bash
cd apps/mobile && flutter test
cd ../../packages/core && dart pub get && dart test
```

If `flutter pub get` reports a version conflict with your Flutter version, run `flutter pub upgrade --major-versions` and tell Claude what changed.

**Test SOS on a real phone with a SIM card.** Emulators cannot send SMS or place calls. Use a friend's number as the contact and tell them first.

## Browser preview

`preview/joruri-bd-preview.html` is a clickable preview with the same design and content. It simulates SMS and calls unless you turn on "Use my phone for real" in Settings. See `preview/README.md`.

## Speed: always test in release mode

`flutter run` on its own builds a **debug** version: it starts slowly and every screen opens slowly, by design (it is built for hot reload, not speed). To see real speed use:

```bash
flutter run --release                      # on the connected phone
flutter build apk --release --split-per-abi   # smaller APKs; install app-arm64-v8a-release.apk on modern phones
```

## Project layout

```
joruri_bd/
  apps/mobile/            Flutter app (Android + iOS)
    lib/app/              app widget, router, dependency providers
    lib/core/             config, logging, connectivity, platform services
    lib/features/<name>/  data / domain / presentation per feature
    lib/l10n/             typed English + Bangla strings
    assets/seed/          bundled emergency numbers and guides (with sources)
    tool/setup.dart       one-time Android/iOS permission setup
  packages/core/          pure Dart: models, phone rules, SOS message (shared with admin + backend later)
  packages/design_system/ colours, theme, shared widgets
```

## Updating information

Once online (SETUP_ONLINE.md), use the **admin website**: every change reaches all phones automatically. The spreadsheet tools below remain for offline/bundled data.

## Adding your blood donors

1. Open `apps/mobile/tool/donors_template.csv` in Excel or Google Sheets. One donor per row:

   | name | blood_group | phone | district | area | available | last_donation | consent | verified |
   | --- | --- | --- | --- | --- | --- | --- | --- | --- |
   | Rahim Uddin | A+ | 01712345678 | Dhaka | Mirpur | yes | 2026-03-02 | yes | no |

   Blood group can be written `A+`, `a+ve`, `O negative`. Phone accepts Bangla digits. District accepts English, Bangla or old spellings (Chittagong, Comilla, Jessore).
2. Save as **CSV UTF-8**, then from `apps/mobile` run:
   ```bash
   dart run tool/import_donors.dart path/to/donors.csv
   ```
   It writes `assets/seed/donors.json` and lists any row it skipped and why.
3. Rebuild the app.

**`consent` must be `yes`.** Only people who agreed to have their number shown are imported. Keep proof of each donor's agreement (a signed form or a recorded message); showing someone's number without it can break the law and puts them at risk of harassment.

Until you import real data, the app shows 40 demo donors marked "Demo data". Their numbers start with `010`, which no operator uses, so a test call cannot reach a real person.

## Adding hospitals, test prices and pharmacies

Fill these spreadsheets in `apps/mobile/tool/` (one row each), save as **CSV UTF-8**, then from `apps/mobile` run:

```bash
dart run tool/import_places.dart hospitals tool/hospitals.csv tool/hospital_tests.csv
dart run tool/import_places.dart pharmacies tool/pharmacies.csv
```

| Sheet | Columns |
| --- | --- |
| `hospitals_template.csv` | id, name, district, area, address, phone, emergency_phone, emergency, blood_bank, ambulance, icu, open_24h, prices_checked_on, verified |
| `hospital_tests_template.csv` | hospital_id (same id as above), test, aliases (other names separated by `\|`, e.g. `CBC\|সিবিসি`), price (taka), note |
| `pharmacies_template.csv` | name, district, area, address, phone, open_24h, verified |

Prices change often: put the date you confirmed them in `prices_checked_on`; the app shows it under every price list and tells people to call to confirm.

## App icon from your logo

```bash
cd apps/mobile && dart run flutter_launcher_icons
```

## Release gate (must be done by a person before any store release)

- [ ] Call or check each number in `assets/seed/emergency_numbers.json` against an official source, then set `"status": "verified"` and the date.
- [ ] A licensed clinician reviews every guide marked `draft` in `assets/seed/guides.json`, corrects it, and it is marked `approved`.
- [ ] In `lib/core/config/app_config.dart` set `showUnverifiedContent`, `showDraftGuides`, `showDemoDonors` and `showDemoPlaces` to `false`.
- [ ] Every donor in `donors.json` has given consent, and you can show proof of it.
- [ ] Test SOS end to end on at least one cheap Android phone and one iPhone, with real SIMs, offline and online.
- [ ] Apply for Google Play's SEND_SMS exception (physical safety / emergency alerts) if you want silent SMS on Android later.

## Deliberate changes from the Phase 1 architecture

1. **Storage.** Phase 3 keeps content as bundled JSON and settings/contacts in the app's private storage, instead of Drift + SQLCipher. The data is tiny (5 numbers, 23 guides, 3 contacts) and this removes a code-generation step and an encryption failure mode. Drift arrives in Phase 5, when thousands of hospitals need queries and sync. Screens will not change: they only see providers.
2. **Strings.** Typed Dart classes instead of ARB files. A missing Bangla string is a compile error, so a blank button cannot ship.
3. **Donor numbers are shown directly** (your decision), instead of "request first, number after the donor accepts". Consent is enforced at import instead. Phase 4 adds in-app donor sign-up with the same consent switch, block and report.

## Known limits (by design of Android and iOS)

- The person must tap **Send** in the SMS app (iOS never allows silent SMS; Android only with a Play exception).
- On iOS the person must confirm every call.
- 999 always opens the dialer pre-filled; Android does not let apps place emergency calls directly.
- No Bangla font is bundled yet; the phone's own Bangla font is used. See `pubspec.yaml` to bundle Hind Siliguri.

## Next: Phase 4

Firebase project, phone sign-in, in-app donor sign-up (merged into the same list), blood requests with push alerts to matching donors, report and block, security rules and the first Dart Cloud Functions.
