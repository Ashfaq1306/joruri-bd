# Changelog

## 1.2.0 (build 13) — 2026-11-03
Includes everything in 1.1.0 (all DGHS hospitals), which was not released on its own.

**Every licensed pharmacy in Bangladesh**
- 117,274 retail pharmacies in all 64 districts from the official DGDA register (Directorate General of Drug Administration): name, upazila, address, drug licence number and licence end date; 22,042 with a phone number.
- Pharmacy screen: choose a district (starts in your profile's district), search by shop name, upazila or bazar, "only with a phone number" and "24 hours" filters. Shops with a valid licence and a phone number first; expired licences are labelled. Shops without a number get a **Directions** button (Google Maps).
- Built into the app per district (works offline, only one district is read at a time). Pharmacist/proprietor names and national IDs in the register are not included.
- Admin panel: a pharmacy can carry its DGDA licence number; it then replaces the built-in entry (to add a checked phone number or mark it 24-hour).

**Medicine prices**
- New **Medicine prices** tab on the Pharmacy screen: search ~38,000 registered medicines by brand (Napa) or generic name (Paracetamol) and see the DGDA-approved maximum retail price per unit for every pack size.
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
