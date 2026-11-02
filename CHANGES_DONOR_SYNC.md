# Donor sync, privacy and Google Sign-In (Spark plan)

See also `firebase/RULES_PROPOSAL.md` (rules NOT DEPLOYED).

| File | Change |
|---|---|
| `apps/mobile/pubspec.yaml` | + `google_sign_in: ^7.2.0` (free; no other new dependency) |
| `apps/mobile/analysis_options.yaml` | `formatter: page_width: 120` so `dart format` keeps the existing style |
| `lib/core/firebase/firebase_ready.dart` | Falls back to `google-services.json` when `firebase_options.dart` is still the placeholder (it was, so Firebase never started); `phoneVerifiedProvider` → `signedInProvider` |
| `lib/core/firebase/google_auth.dart` | **New.** Google Sign-In (7.x API) → Firebase Auth; optional `--dart-define=GOOGLE_WEB_CLIENT_ID` |
| `lib/features/profile/data/profile_sync.dart` | Rewritten: update-only-own-fields, else create with `hidden:false, verified:false`; consent withdrawal = `shareConsent:false` (no delete); awaited with timeouts; returns `SyncStatus`; no unhandled errors; "Delete my data" deletes only if not admin-hidden |
| `lib/features/profile/presentation/profile_sync_controller.dart` | **New.** Tracks online status separately from the local save; remembers unfinished syncs; retries when back online |
| `lib/features/profile/presentation/profile_controller.dart` | `save()` saves locally then hands off to the sync controller (never throws); `saveAndSync()` for callers that want the result |
| `lib/features/profile/presentation/sign_in_screen.dart` | **New**, replaces `verify_phone_screen.dart` (SMS needs the paid plan) |
| `lib/features/profile/presentation/profile_card.dart` | Online status line, Sign in / Try again; **bug fix: "Sign out" used to delete the online profile** |
| `lib/features/profile/presentation/profile_screen.dart` | Instant local save; online result shown on the card |
| `lib/features/blood/data/remote_donors.dart` | Signed-in (not phone) gate; keeps your `shareConsent`/`hidden` filters; limit 300 to match rules |
| `lib/features/blood/presentation/donor_list_screen.dart` | Sign-in banner; "online list not available, showing saved donors" when refused |
| `lib/features/settings/presentation/settings_screen.dart` | "Delete my data" also signs out of Google |
| `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/app/router.dart` | `/sign-in` (old `/verify` redirects) |
| `lib/main.dart` | Retries an unfinished profile sync when the phone comes online |
| `lib/l10n/*` | 17 new strings, English + Bangla |
| `test/profile_sync_fields_test.dart` | **New.** Updates never send admin fields; new listings start unverified; consent withdrawal turns the listing off |
| `firebase/firestore.rules` | Now your **locked production rules** (safe if deployed by accident) |
| `firebase/firestore.rules.PROPOSED-NOT-DEPLOYED`, `firebase/RULES_PROPOSAL.md` | **New.** Proposal + explanation + test plan |
| `firebase/firestore.indexes.json` | Optional donor index |
| `SETUP_ONLINE.md` | Spark + Google Sign-In; no billing/SMS; website deploy no longer touches rules |

Untouched: admin website, offline/bundled data, content sync, all other features.
Your `*.bak` files in `lib/` were kept (not compiled); delete them when you no longer need them.

## Follow-up: admin sign-in and Fedora setup

| File | Change |
|---|---|
| `admin/backend-firebase.js` | + **Sign in with Google** (popup, falls back to redirect if the popup is blocked). Email/password kept as an option. |
| `admin/app.js` | Login screen: Google first, email/password under "Use email and password instead". New **"Database is locked"** screen when the admin check is refused by the locked rules (it used to wrongly say "Not an admin"). Both screens show the User UID with a Copy button. Admin authorization unchanged: only UIDs in `admins` (console-only) are admins. |
| `admin/index.html`, `admin/README.md` | Styles for the new login layout; README updated. |
| `firebase.json` | **Hosting only.** `firebase deploy` can no longer touch rules or indexes. |
| `firebase.rules-deploy.json` | **New.** The only config that references the rules/indexes; used deliberately via `--config`. |
| `firebase/RULES_PROPOSAL.md` | Deploy/undo commands use `--config firebase.rules-deploy.json`; still **NOT DEPLOYED**. |
| `SETUP_ONLINE.md` | Rewritten for Fedora (dnf, Bash, `~/` paths): tools, Google sign-in, SHA-1/SHA-256, `google-services.json`, admin website config, local test, **hosting-only** deploy, making yourself admin, what works while rules are locked, troubleshooting. |
| `README.md` | Note updated. |

No Dart/Flutter files changed in this follow-up.
