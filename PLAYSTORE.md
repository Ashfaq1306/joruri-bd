# Publishing Joruri BD on Google Play

Everything the app needs for Google Play is in this repository. The steps
below are the ones only the account owner can do in
[Play Console](https://play.google.com/console).

## 1. The file to upload

`apps/mobile/tool/release.ps1` builds it with every release:

- `apps/mobile/build/release-upload/joruri-bd-play.aab`, also attached to each
  [GitHub release](https://github.com/Ashfaq1306/joruri-bd/releases) as
  `joruri-bd-play.aab`.
- Build it by hand: `flutter build appbundle --release --dart-define=PLAY_STORE=true`.

Differences from the APK on the download page:

- **Updates come from Google Play.** The app's own updater is switched off:
  no "Update available" banner, and Settings → About opens the Play listing.
- **No `REQUEST_INSTALL_PACKAGES` permission.** Play does not allow an app to
  install updates itself. `android/app/src/play/AndroidManifest.xml` removes the
  permission, and `release.ps1` stops if it is ever back.

Facts about the build (checked for 1.9.0):

| | |
| --- | --- |
| Package name | `bd.joruri.joruri_bd` |
| Target API | 36 (Android 16), minimum API 26 (Android 8) |
| Signing | the Joruri release key (`android/key.properties`), SHA-256 `97:84:0D:75:17:DE:69:AB:7C:C8:89:38:16:83:82:0E:21:85:04:0B:0C:49:6D:3B:1B:10:B7:64:8A:4A:BE:32` |
| Version | from `pubspec.yaml` (`1.9.0+21` → version code 21) |

**Signing.** Use Play App Signing. Upload the bundle signed with the Joruri
release key; that key becomes the *upload key*. Keep `key.properties` and the
`.jks` file backed up. Without them no update can be uploaded.

**Google sign-in from Play.** Play re-signs the app with its own *app signing
key*. Copy the SHA-1 and SHA-256 of that key from Play Console → Test and
release → App integrity, and add both in Firebase Console → Project settings →
Android app `bd.joruri.joruri_bd` → *Add fingerprint*. If you skip this, Google
sign-in fails on copies installed from Play. E-mail and password login keeps
working either way.

## 2. Store listing

- **App name:** Joruri BD – Emergency Help (`জরুরি বিডি`)
- **Category:** Medical. **Contact e-mail:** joruribd.2026@gmail.com. **Website:** https://joruri-bd.web.app
- **Privacy policy:** <https://joruri-bd.web.app/privacy/>
- **App icon (512×512):** `playstore/icon-512.png` (from `apps/mobile/assets/images/app_icon.png`).
- **Feature graphic (1024×500):** `playstore/feature-graphic.png`.
- **Phone screenshots (1080×1920, 9:16):** `playstore/screenshots/1-home.png` … `8-firstaid.png`, in that order.
  Taken on an emulator set to 1080×1920 (Play needs 16:9 or 9:16), app in English, location Dhaka.

Short description (80 characters max):

> SOS, 999, blood donors, hospitals, pharmacies and disaster alerts for Bangladesh.

> জরুরি SOS, ৯৯৯, রক্তদাতা, হাসপাতাল, ফার্মেসি ও দুর্যোগ সতর্কবার্তা — এক অ্যাপে।

Full description (English; add the Bangla one as a translation):

> Joruri BD helps you in an emergency in Bangladesh, even with no internet.
>
> • SOS: one tap opens an SMS with your exact location to the people you chose, ready to send, then calls them. No contacts saved? It calls 999.
> • Emergency numbers: 999, police, fire service, ambulance services by city, women and children helplines.
> • Blood donors: find donors by blood group and district and call them.
> • Hospitals and blood banks: all hospitals and clinics registered with DGHS, with phone numbers and government test prices.
> • Pharmacies: licensed pharmacies in every district, and DGDA medicine prices.
> • Disaster alerts: cyclone signals, heavy rain, heat waves and felt earthquakes for your district, with what to do.
> • First aid and disaster guides in Bangla and English.
> • Toolkit: flashlight, siren, compass, GPS coordinates.
>
> Free, no ads. Create an account once to save your profile and emergency contacts; log in on any phone to get them back. Delete your account and data any time in Settings.
>
> Joruri BD is not a government service. In a life-threatening emergency, always call 999.

## 3. App content (Policy → App content)

**Privacy policy:** `https://joruri-bd.web.app/privacy/`

**Ads:** No ads.

**App access:** most of the app works without logging in. For the reviewer,
create one account in the app and give its e-mail and password under *App
access → All or some functionality is restricted*. It is needed for the blood
donor list and for saving the profile.

**Account deletion** (required because users can create accounts):
- In the app: Settings → Privacy → **Delete my data** → Delete forever.
- On the web: <https://joruri-bd.web.app/delete-account/>
- Both delete the account, the profile, the donor listing and the emergency contacts.

**Data safety form.** What was entered in Play Console on 2026-11-28 (keep it in step with the app):

| Data type | Collected | Shared | Why | Optional |
| --- | --- | --- | --- | --- |
| Name | Yes | No | App functionality, account management | Yes |
| E-mail address | Yes (account) | No | App functionality, account management | Yes (account is optional) |
| User IDs (Firebase account ID) | Yes | No | App functionality, account management | Yes |
| Phone number | Yes | No | App functionality | Yes |
| Other info: blood group, district, area | Yes | No | App functionality | Yes |
| Contacts (emergency contacts the user types in) | Yes, when logged in | No | App functionality | Yes |
| Device or other IDs (Firebase installation ID, for alert notifications) | Yes | No | App functionality | No (required) |
| Location | **No** (used on the phone only; the user sends it by SMS themselves) | No | | |
| App activity, crash logs, analytics | No | No | | |

- None of it is processed only ephemerally; all is encrypted in transit (HTTPS).
- Not marked as "shared": the donor listing (name, number, blood group, district) is shown to logged-in users only when the person chooses to be listed, which Google treats as a user-initiated transfer.
- Accounts: e-mail and password, and OAuth (Google). Account deletion link: <https://joruri-bd.web.app/delete-account/>.
- No advertising ID (Advertising ID declaration: No). Ads: No. Government app: No. Financial features: none.
- Health apps declaration: Emergency and first aid; Healthcare services and management; Medical reference and education.

**Target audience:** 13 and over (it is not a children's app).
**Content rating:** fill in the IARC questionnaire. There is no violence,
gambling or user chat; there is user-provided content in the donor list
(names and numbers only), and the app shares location by SMS, sent by the user.
**Health apps declaration:** the app gives first-aid information and
emergency contacts; it is not a medical device and does not diagnose.
**Government apps:** answer *No*. Joruri BD is not made by the government. The
app says so, and it only links to official numbers.

## 4. Permissions and review notes

| Permission | Why |
| --- | --- |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Put the location into the SOS text and show it on the "My location" screen. Foreground only, never in the background. |
| `CALL_PHONE` | SOS calls the first emergency contact, or 999, after the SMS. |
| `POST_NOTIFICATIONS`, `VIBRATE` | Disaster alerts. |
| `INTERNET` | Content updates, alerts, account. |

The app does **not** use `SEND_SMS`: it opens the phone's SMS app and the
user taps Send. So the SMS and Call Log permissions declaration is not needed.

## 5. Release tracks

1. Upload the `.aab` to **Internal testing** first and install it from the
   test link on a real phone. Check that login, logout, delete my data, SOS,
   calls and alerts work.
2. New personal developer accounts must run a **closed test with at least 12
   testers for 14 days** before Production is unlocked.
3. Then promote the same release to **Production**.

For each new version: raise the version in `pubspec.yaml`, run `release.ps1`,
and upload the new `joruri-bd-play.aab` in Play Console.
