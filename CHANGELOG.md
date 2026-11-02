# Changelog

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
