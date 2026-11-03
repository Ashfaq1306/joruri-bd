# Firebase backend (project `joruri-bd`, free Spark plan)

| File | What it is |
|---|---|
| `firestore.rules` | The **live** security rules. Deploy: `firebase deploy --only firestore:rules` (repo root). |
| `firestore.indexes.json` | Optional donor index. |
| `rules-test/` | 27 automated checks of the rules in the local emulator: `cd firebase/rules-test && npm install && npm test` (needs Java 21+). Run before every rules deploy. |

## What the rules enforce

| Data | Who can read | Who can write |
|---|---|---|
| `meta/content` (version), `meta/app` (app version, switches) | Everyone | Admins |
| `emergency_numbers`, `guides`, `hospitals`, `pharmacies`, `announcements` | Everyone, **published items only** | Admins |
| `snapshots/{list}-{n}` (packed copies phones download) | Everyone | Admins (the website rebuilds them on every save) |
| `donors` (list) | Signed-in users, only `shareConsent == true && hidden == false`, ≤ 300 per query | Owner of the listing (own fields only, cannot verify/un-hide themselves); admins |
| `users/{uid}` | Owner, admins | Owner |
| `admins/{gmail}` | Admins (everyone may check their own entry) | **Owners** only; an owner cannot remove themselves |
| `audit` | Admins | Admins add; nobody edits or deletes |

Admins are identified by their **verified Google e-mail** (document ID = lower-case address) with `role: owner | editor`. Owners now: ashfaqur87654@gmail.com, rhmugdho5@gmail.com.

## How phones get updates

On every save the admin panel rebuilds the packed copy of that list (`snapshots/hospitals-0…5`, each ≤ 900 KB) and raises `meta/content.version`, recording the list's new stamp in `meta/content.stamps`. The app listens to that document live, downloads only lists whose stamp changed (~11 reads for everything, instead of one read per hospital), and saves them on the phone (works offline afterwards). Free plan limits: 50,000 reads and 20,000 writes per day. `meta/app` is listened to the same way for update notices and switches.

## Known limits

- Any Google account can sign in to the app and read listed donors (300 per query). **Firebase App Check** (free) would restrict reads to the genuine app; recommended next step.
- Push notifications when the app is closed need Cloud Functions (paid Blaze plan). Announcements appear as soon as the app is opened or is running.
