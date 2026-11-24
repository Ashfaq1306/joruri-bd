# Changelog

## 1.10.0 (build 22) — 2026-11-24
**Location on when you open the app (like bKash)**
- When the app opens and the phone's **location is switched off**, Google's one-tap **"Turn on device location"** dialog appears straight away: tap **Turn on** and it's done, no searching through the settings. Phones without Google Play services open the location settings instead.
- When Joruri BD **may not use the location**, a short screen first says why (SOS sends your exact location to your contacts; never read in the background), then Android asks. Blocked in the phone settings → it says where to allow it and opens the settings.
- Asked again when you come back to the app after 30 minutes or more, or after changing it in the settings. **"Not now"** is respected for the rest of the session, and nothing is ever asked on the SOS, road-accident or onboarding screens. The notification question now waits until the location question is answered, so two system dialogs never stack.
- While location is off or not allowed, Home shows an amber **"Location is off: SOS cannot send where you are"** bar; one tap fixes it.
- On the SOS result and My location screens, **Turn on location** now uses the same one-tap dialog.

**Emergency and ambulance numbers checked**
- Every unverified number was checked online on 2026-11-24 against the hospital's own website, a government press release, or an embassy list of medical facilities. **17 of the 44 numbers are now verified** (was 9), each with its source and date in the app:
  - Police Headquarters control room 01320-001223 (Home Ministry press release, 2 Feb 2026).
  - Evercare Dhaka (ambulance 01714-090000, hotline 10678), Ad-din Medical College Hospital (01713-488411/12, 10610), Ad-din Akij Khulna (01713-488422), Bangladesh Eye Hospital Khulna (01799-209075).
- **Three numbers had changed since the 2021 list and were corrected**:
  - STS Chattogram Apollo is now **Evercare Hospital Chattogram**: ambulance 01313-779966, hotline 10663 (was 01714-162759).
  - **Gazi Medical College Hospital**, Khulna: ambulance 01407-031030/31, hot line 01405-100100 (was 01779-656722).
  - **United Hospital**: emergency 01914-001234 (was 01914-001326).
- Labaid's hotline 10606 was added as another number; its ambulance mobile stays unverified.
- 27 numbers (26 ambulance services and Shastho Batayon 16263), plus the 15 fire stations whose printed numbers were wrong, have no current official source online and still need a phone call. They keep their "not yet verified" label. Call list with a checkbox per number: `tools/police-import/numbers_to_call.md` (`node tools/police-import/call_list.mjs` rebuilds it). Mark each one verified on the admin website after calling.
- Publish to phones that are already installed: `node tools/police-import/emergency_numbers.mjs --publish`.

## 1.9.0 (build 21) — 2026-11-21
**Log out really logs out**
- **Log out** (Settings → My profile) now removes your profile and emergency contacts from the phone, so nothing of yours is shown afterwards. Before, the account was signed out but your name, number and contacts stayed on screen.
- Your **emergency contacts are now saved with your account** (with the profile), so logging in again, on this phone or a new one, brings back both. Before logging out, the app saves your latest changes online; if that is not possible (no internet), it warns you first.
- Asks "Log out?" before logging out. Logged in without a profile yet? The profile card shows who is logged in and a Log out button.

**Delete my data deletes your account**
- "Delete my data on this phone" is now **Delete my data**. When you are logged in, it permanently deletes your **account**, your profile, your blood donor listing (also one an admin had hidden) and your emergency contacts, online and on the phone, then the app starts again from the welcome screen. Without an account it clears the phone as before.
- For safety, Firebase asks you to confirm it is you (password, or choose your Google account again) when you logged in more than a few minutes ago. Nothing is removed from the phone unless the online data is really gone; no internet → clear message, try again.
- New web page to delete an account without the app: <https://joruri-bd.web.app/delete-account/> (required by Google Play), and a **privacy policy**: <https://joruri-bd.web.app/privacy/> (Settings → Privacy → Privacy policy).
- Database rules: profiles may hold up to 5 emergency contacts; owners can always delete their own donor listing (`firebase/rules-test`, 52 checks).

**Ready for Google Play**
- New Google Play build (`joruri-bd-play.aab`, built by `release.ps1` and attached to every release): updates come from Play, so the in-app APK updater and its `REQUEST_INSTALL_PACKAGES` permission are left out (Play does not allow self-updating apps). Targets Android 16 (API 36). Step-by-step guide, store texts and Data safety answers: `PLAYSTORE.md`.
- The release script also deploys the database rules.

**Fixes**
- Back on the Guides or Settings tab goes to Home instead of closing the app.

## 1.8.0 (build 20) — 2026-11-17
**Log in once: accounts with e-mail and password**
- New **Log in / Create account** screen. Create an account once with an e-mail address and a password (or Google), then just **log in**, on this phone or a new one. No more e-mail links (the free plan allowed only 5 a day for everyone). The phone stays logged in until you sign out.
- **Your profile comes back when you log in.** It used to be only sent online, never read back, so after reinstalling the app or changing phone people had to fill in the account form again. Now the profile saved with the account is restored by itself (also at app start when logged in with no profile on the phone).
- Onboarding: **"Already have an account? Log in"** above the account form; after logging in, the form is skipped. After filling the form, the next screen opens on **Create account**. Settings → profile card: **Log in** button when there is no profile on the phone.
- **Forgot password?** sends a reset e-mail. People who signed in with Google or an e-mail link before can use it to set a password for the same account.
- Clear messages for wrong password, address already registered (switches to Log in), short or mismatched passwords and no internet.

**Ambulance services by city**
- The Ambulance screen now lists **33 hospital and private ambulance services** in Dhaka, Chattogram, Cumilla, Rajshahi and Khulna, grouped by city with your district first, each with address, a call button and its other numbers. 999 stays at the top.
- Source: the MedicsBD ambulance list (medicsbd.com/ambulance-info). The live page showed no entries on 2026-11-17 ("The list is being updated"), so the list MedicsBD published (Wayback Machine copy of 12 Aug 2021) was used. Only services with a mobile number were imported; landline-only entries use 7-digit Dhaka numbers from before the BTCL renumbering and cannot be dialled as printed. All entries are marked **not yet verified** until someone calls them (`tools/police-import/ambulances.mjs`).
- The list of all numbers links to the ambulances instead of listing them. The admin website's Emergency numbers page can now set a district, an address and other numbers.

## 1.7.0 (build 19) — 2026-11-15
**Disaster alerts and warnings**
- New **Disaster alerts** screen (Home → Disaster): the active warnings for your district first, then the rest of the country, with level (Advisory, Be alert, Warning, Emergency), area, issue and end time, and the source.
  - Weather and cyclone warnings come from the **Bangladesh Meteorological Department's official Common Alerting Protocol feed** (cap.bmd.gov.bd), in Bangla and English. The districts a warning covers are worked out from BMD's own area map and place names.
  - **Earthquakes** that can be felt in Bangladesh come from the US Geological Survey, minutes after they happen, with the nearest district and distance.
  - The team can issue its own alerts on the admin panel (new **Disaster alerts** page), e.g. river flood warnings from FFWC or evacuation orders, for the whole country, divisions or districts, with or without a notification.
- **Phone notifications**, also when the app is closed: the alert watcher (`tools/alerts`, GitHub Actions every 10 minutes, keyless sign-in with workload identity) publishes the list to Firestore `meta/alerts` and sends each new serious alert to the FCM topics of the districts it covers (`alerts-bn-<district>`, `alerts-en-<district>`, `alerts-<lang>-all`). Danger signals and strong earthquakes use a high-priority channel. Settings → Disaster alerts: on/off, your district (default: your profile's), or all of Bangladesh. Android 13+ asks once for permission.
- Every alert says **what to do now**: the meaning of the storm signal, BMD's own instruction, and the steps of the matching guide. New **Cyclone signals** page (what signals 1–11 mean and what coastal families should do at each), **Emergency bag checklist**, and a **1090** button (free government forecast and early-warning line).
- **Earthquakes cannot be predicted.** The alert screen explains how to check that Android's own Earthquake Alerts (active in Bangladesh since 2022) is on: it is the only warning that arrives seconds *before* strong shaking.
- Red/orange banner on Home when a warning covers your district.
- If the watcher stops, the app reads BMD and USGS itself while it is open, and keeps the last list for offline use.

**Guides**
- All eight disaster guides written, in Bangla and English, with new sections **Get ready before it comes** and **After it has passed**: flood, cyclone and storm surge, earthquake, lightning, landslide, nor'wester, and new **heat wave** and **cold wave** guides (BMD temperature bands). Sources: Standing Orders on Disaster, BMD, CPP, FFWC, IFRC, WHO.
- The 12 first-aid guides that said "being written" now have content: heart attack, stroke, unconscious person and CPR, fracture, drowning, animal bites (rabies), poisoning, seizure, road accident, building fire, gas leak, building collapse (IFRC 2020 guidelines).
- All guides are marked **draft** with a banner until a doctor (first aid) or the Department of Disaster Management (disaster) approves them on the admin panel. Existing phones get the new text within seconds (content snapshot); the admin guide form has the two new sections.

## 1.6.0 (build 18) — 2026-11-06
**Medicines and pharmacies on the admin panel**
- Admin panel: new **Medicines & prices** page. Search all 38,834 brands of the DGDA price list that are built into the app, then **Edit** one to correct its price or details, **Hide** it, or **+ Add** a medicine DGDA does not list. Deleting a change brings back the DGDA entry. The app shows corrected entries with "Checked and updated by the Joruri BD team (date)".
- Admin panel: the **Pharmacies** page can now search the 117,274 DGDA register shops built into the app (choose a district): **Edit** a shop to add its phone number or mark it open 24 hours, or **Hide** it (closed, wrong). The phone number is now optional.
- Phones from 1.6.0 apply these changes within seconds (new lists `medicines` and `pharmacy_hides` in the content snapshots; older versions ignore them). The admin website gets copies of the DGDA lists at every deploy (`tools/admin-data/copy.mjs`, hosting predeploy).
- Firestore rules: new `medicines` collection (read if published, write admins only).
- Admin panel fix: forms and lists no longer show a stray "null".

## 1.5.0 (build 17) — 2026-11-05
**Every fire station in Bangladesh**
- New **Fire stations** screen (Fire Service → "Your local fire station", also under All numbers): 543 fire stations and 94 Fire Service offices in all 64 districts, each with its number and a Call button, in Bangla and English, with directions. Starts in your profile's district; type a station or upazila name to search the whole country. The district's own station comes first, offices last. Works offline.
- Source: the Fire Service and Civil Defence lists of station and office numbers for the eight divisions (`tools/fire-import/source/`). The PDFs use a legacy Bangla font, so the 638 rows were typed from the page images and every number was checked by `tools/fire-import/build.mjs`.
- 15 numbers were misprinted in the lists (12 digits, an old Dhaka land line, or the same number printed on two stations). They are **not** dialled: those entries say "Number being checked. Call 999 or 102 meanwhile." until an admin enters the confirmed number. List and probable numbers: `tools/fire-import/report.txt`.
- Admin panel: new **Fire stations** page (rows to check are marked ⚠; the dashboard counts them). The phones of every version from 1.5.0 get edits within seconds.
- Admin panel fix: emptying a field in an edit form now removes it (before, the old value came back after Save). Seed import also accepts `police_stations.json` and `fire_stations.json`.

## 1.4.0 (build 16) — 2026-11-04
**Automatic updates (through Firebase)**
- When a new version is published (Firebase `meta/app`, set by the release script), the app now downloads it **inside the app**: by itself on Wi-Fi, on a tap on mobile data, with a progress bar. It checks the file's SHA-256 against `meta/app` (GitHub's digest of the release asset) and then opens Android's installer: one tap on **Update**. Android only lets app stores install silently, so that last tap stays. The first time, Android asks once to allow Joruri BD to install updates.
- If the in-app download fails, the card offers **Download in browser** (the old way). Downloaded files are deleted after the update.
- `meta/app` now links to the release's own files (`releases/download/<tag>/…`, not `latest`), so the checked SHA-256 always matches. New fields `apkSha256` / `apkSha256Arm32`, filled by `tools/announce_release.mjs` and by "Use latest release" on the admin panel.
- Phones on 1.3.1 or older still update once the old way (browser); from 1.4.0 on, updates come in the app.
- The update card's button now has white text (the dark-green-on-green text was hard to read).

**Sign in with e-mail (free, no SMS)**
- Sign-in screen: besides Google, type your e-mail and tap **Send sign-in link**; tapping the link in the e-mail opens the app and signs you in (Firebase e-mail link; Android App Links on `joruri-bd.firebaseapp.com`, whose `assetlinks.json` Firebase serves for the release key). If the link opens in a browser, paste it into the app; `joruri-bd.web.app/signin/` explains this.
- SMS one-time codes are not possible on the free Firebase plan (Blaze only, charged per SMS).
- **Limit:** on the free Spark plan Firebase sends only **5 sign-in e-mails per day for the whole project**. When it is reached the app says so and points to Google sign-in, which has no such limit. More e-mails need the Blaze plan.

## 1.3.1 (build 15) — 2026-11-04
**Google sign-in works for everyone**
- Fix: "Sign in with Google" failed on every phone with "Sign-in did not work" (`clientConfigurationError`) in all published versions. Release builds shrink unused resources, and the Web client ID that Google sign-in looks up by name (`default_web_client_id`, generated from `google-services.json`) was removed from the APK. `android/app/src/main/res/raw/keep.xml` now keeps it, and the release scripts refuse to publish an APK without it.
- Checked with the APK from GitHub on a fresh phone with no account: the app opens, shows Online and loads live content without signing in, on any network, from the free Firebase plan (no billing account, no App Check, release signing key registered).

## 1.3.0 (build 14) — 2026-11-04
**Every police station in Bangladesh**
- New **Police stations** screen (Police → "Your local police station"): all 630 thanas in all 64 districts (DMP, CMP, KMP, RMP, BMP, SMP, GMP, RPMP and district police) with the **officer in charge's (OC) mobile number** and a Call button, names in English and Bangla, directions, and address + e-mail for Dhaka (DMP) stations. Starts in your profile's district; type a thana name to search the whole country. Works offline.
- Source: the RAB list of police-station OCs (01320 series, October 2024, `tools/police-import/source/thana-services.pdf`), cross-checked against an independent Cumilla list (all 18 match). Not used: the older `OC_Contact_List` PDF (01713 series; same number on several thanas, 10-digit numbers) and the DMP website's phone numbers (011 Citycell numbers, closed in 2016, and pre-2018 7-digit land lines). Two numbers that break their district's sequence (Rajpur, Jhalokati; Shashibhushan, Bhola) are left out until checked. Brahmanbaria Sadar and Chandpur Sadar are not in the source.
- Admin panel: new **Police stations** page (edit an OC number when it changes; phones update within seconds). Refresh scripts: `tools/police-import`.

**Emergency numbers (live on all phones, also older versions)**
- Checked against the Bangladesh Police and Fire Service websites and marked verified: 999, 102, 109, 1098, 333.
- Added: Police Headquarters control room 01320-001223 (24 h), Fire Service headquarters control room 02-223355555, 1090 disaster early warning, 16430 government legal aid, 106 Anti-Corruption Commission.
- 16263 (Shastho Batayon): now links to DGHS and warns that the service had funding problems in 2026.
- Fix: the Fire Service card showed an internal note ("confirm … before marking verified") to users.
- Fix: the list was never sorted, so 102 could appear above 999. 999 is now always first (also for older app versions, by publishing in that order).
- Long numbers (01320-001223) get their own line instead of squeezing the name.

**Bug fixes found by testing on a phone**
- **Hospital search found nothing**: typing any name (e.g. "Dhaka Medical") showed "No hospital in our list" because the district check also compared the text with an empty area. Fixed, with a test.
- **Tests & prices**: the text box from the Hospitals tab was used as an area filter, so "CBC" found no hospital after a name search. It now matches hospital name, area or address ("CBC" + "Dhaka Medical" = CBC at Dhaka Medical College Hospital).
- Phones were never told about 1.2.0: the release was published but the admin panel still announced 1.0.1. The release scripts now announce each release automatically (`tools/announce_release.mjs`), and the dashboard warns if GitHub has a newer release than phones are told about.

**One repository**
- `Ashfaq1306/joruri-bd` is now public and holds the code **and** the APK releases. `joruri-bd-releases` is archived; its old download links keep working.

## 1.2.0 (build 13) — 2026-11-03
Includes everything in 1.1.0 (all DGHS hospitals), which was not released on its own.

**Every licensed pharmacy in Bangladesh**
- 117,274 retail pharmacies in all 64 districts from the official DGDA register (Directorate General of Drug Administration): name, upazila, address, drug licence number and licence end date; 22,042 with a phone number.
- Pharmacy screen: choose a district (starts in your profile's district), search by shop name, upazila or bazar, "only with a phone number" and "24 hours" filters. Shops with a valid licence and a phone number first; expired licences are labelled. Shops without a number get a **Directions** button (Google Maps).
- Built into the app per district (works offline, only one district is read at a time). Pharmacist/proprietor names and national IDs in the register are not included.
- Admin panel: a pharmacy can carry its DGDA licence number; it then replaces the built-in entry (to add a checked phone number or mark it 24-hour).

**Medicine prices**
- New **Medicine prices** tab on the Pharmacy screen: search 38,834 registered medicines (22,525 with a published price) by brand (Napa) or generic name (Paracetamol) and see the DGDA-approved maximum retail price per unit for every pack size.
- Each medicine lists the **same medicine from other companies, cheapest first**, with a reminder to ask a doctor or pharmacist before changing brands.
- Veterinary products and raw materials are left out. Brands without a published price say so; nothing is estimated.
- Source and refresh scripts: `tools/dgda-import`.

## 1.1.0 (build 12) — 2026-11-03
**Every registered hospital in Bangladesh**
- 8,616 facilities from the official DGHS Facility Registry: 834 government hospitals (all 37 medical college hospitals, 60 district/general hospitals, 434 upazila health complexes, specialised institutes, MCWCs, trauma centres, CMHs), 5,926 private hospitals/clinics, 1,626 NGO hospitals/clinics and 198 blood banks. Names in English and Bangla, type, upazila, address (8,084), phone (6,425), email, website, map position (4,878), beds.
- Government test fees from the Ministry of Health user-fee chart (CBC 150, X-ray chest 200, ECG 80, ultrasound 110/220, CT brain 2,000, MRI 3,000/4,000 …), shared through `fee_charts.json`. No private prices (no official source).
- Hospitals screen: search by name in English or Bangla, Government / Private / Emergency / Blood bank filters, fast list for thousands of entries, exact map position, every phone number, email, website, data source.
- Blood screen: "Blood banks and hospital blood units" shortcut.
- The list is built into the app (works offline from the first start) and updated from the admin panel.

**Scale (free plan)**
- Content is packed into a few large documents (`snapshots/`): a phone downloads everything with ~11 reads instead of ~8,650, and only re-downloads lists that changed.
- Admin dashboard uses server counts; tables show 300 rows at a time with search; large JSON is decoded off the UI thread.
- Admin hospital form: Bangla name, type, government, other numbers, email, website, map position, beds, source.
- `tools/dghs-import`: scripts to refresh the list from DGHS.

## 1.0.1 (build 11) — 2026-11-03
- Fix: content sync crashed when the content version carried a server timestamp, so phones stopped receiving updates.
- Onboarding text no longer promises SMS (OTP) verification; explains Google sign-in instead.

## 1.0.0 (build 10) — 2026-11-03
Everything online is switched on (free Firebase Spark plan).

**Admin panel** (https://joruri-bd.web.app)
- New pages: **Announcements** (home-screen notices with level, button and date range), **App & updates** (tell phones about new versions, minimum version, content switches), **Admins** (owners add/remove admins by Gmail, owner/editor roles), **Backup** (full JSON export).
- Dashboard: to-do list of missing data, "Send content to phones now".
- Redesigned look with icons, dark mode and a mobile menu.
- Fix: list sorting was computed but never applied.
- Fix: adding a hospital/guide whose generated ID already existed silently overwrote the existing item.
- Saving shows progress; Esc / clicking outside closes the editor.

**App**
- Content updates arrive **live** (within seconds) while the app is open, not only at start-up.
- Fix: a change published while a download was running was skipped until the next app start.
- Announcements from the admin panel on the home screen (urgent ones cannot be closed).
- "Update available" card and Settings → **Check for updates**; required updates never block SOS.
- Admins can switch draft guides / unchecked numbers on or off remotely.
- Settings shows the real installed version.
- Fix: opening a hospital while the list was loading showed "Something went wrong".
- Fix: two analyzer warnings.

**Build and release**
- Fix: Android build failed with Java 25 (Gradle 8.12). Upgraded to Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0.
- Shared release signing key (not in git) so every APK installs as an update; release scripts `tool/release.ps1` / `tool/release.sh`; APKs on GitHub releases (`Ashfaq1306/joruri-bd-releases`), public download page.

**Backend**
- Firestore rules deployed (were fully locked) with admin roles; 27 automated rules tests in `firebase/rules-test`.
- Admin web app registered; database seeded with the app's emergency numbers and guides.
