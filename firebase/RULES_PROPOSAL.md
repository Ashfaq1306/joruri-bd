# Firestore rules proposal — NOT DEPLOYED

| File | What it is |
|---|---|
| `firestore.rules` | Your current **live** rules (everything locked). Only `firebase.rules-deploy.json` points here; `firebase.json` is **hosting-only**, so `firebase deploy` can never touch rules. |
| `firestore.rules.PROPOSED-NOT-DEPLOYED` | The proposal below. Not referenced by any config file. |
| `firestore.indexes.json` | One optional composite index for the donor query. |

## What the proposal enforces

| Data | Who can read | Who can write |
|---|---|---|
| `meta`, `emergency_numbers`, `guides`, `hospitals`, `pharmacies` | Everyone, **published items only** (`meta` fully) | Admins only |
| `donors` (list) | Signed-in users, **only** `shareConsent == true && hidden == false`, at most 300 per query | — |
| `donors/{uid}` (own) | Owner, admins | Owner: create with `hidden == false`, `verified == false`; update **only** name, bloodGroup, phone, districtId, area, available, shareConsent, lastDonation, updatedAt; delete only if not hidden by an admin. Admins: anything |
| `users/{uid}` | Owner, admins | Owner only, fixed set of fields |
| `admins` | Your own entry only | Nobody (console only) |
| `audit` | Admins | Admins create; nobody edits or deletes |
| anything else | nobody | nobody |

Matching the app exactly:

- Donor query `where(shareConsent == true).where(hidden == false).where(bloodGroup in […]).limit(300)` satisfies the list rule. A query without those filters is refused, so privacy does not depend on the app's own filtering.
- Profile updates send only the owner's fields; new listings are created with `hidden: false, verified: false`, as the create rule requires.
- Content sync queries `where(published == true)`, as the read rules require.
- The admin website reads everything and writes everything; it passes `isAdmin()`.

Google sign-in only proves control of a Google account. It does not verify identity, phone number or health; phone numbers are format-checked only. The admin **verified** flag is the only trust badge, and users cannot set it.

## Known limits (honest)

- Any Google account can sign in and read listed donors (300 per query). Repeated queries can still collect many numbers. **Firebase App Check** (free) would restrict reads to your genuine app; recommended next step.
- Donor records created by older app versions may have no `hidden` field and will not appear in the list until an admin opens and saves them (the admin form always writes `hidden`).

## Index

The donor query uses only equality / `in` filters, which Firestore can usually serve by merging single-field indexes, so it should work **without** a composite index. If the app logs a `failed-precondition` error with an index link, deploy the included index (free):
```bash
firebase deploy --config firebase.rules-deploy.json --only firestore:indexes
```

## Testing before deploying

Firebase console → Firestore → **Rules** → paste the proposal into the editor **without publishing** → **Rules Playground**. Try:

1. `get /databases/(default)/documents/donors/SOMEUID`, unauthenticated → **denied**.
2. Authenticated as UID `u1`: `create /donors/u1` with `hidden: true` → **denied**; with `hidden: false, verified: false` and valid fields → **allowed**.
3. As `u1`: `update /donors/u1` changing `verified` to `true` → **denied**; changing `available` → **allowed**.
4. As `u1`: `create /admins/u1` → **denied**.

## Deploying (only when you decide; NOT part of hosting setup)

Run from the top project folder (the one containing `firebase.json`):
```bash
cp firebase/firestore.rules firebase/firestore.rules.LOCKED-BACKUP
cp firebase/firestore.rules.PROPOSED-NOT-DEPLOYED firebase/firestore.rules
firebase deploy --config firebase.rules-deploy.json --only firestore:rules
```
To go back to the locked rules:
```bash
cp firebase/firestore.rules.LOCKED-BACKUP firebase/firestore.rules
firebase deploy --config firebase.rules-deploy.json --only firestore:rules
```
The admin website needs these rules (or similar) to work: with the locked rules it shows "Database is locked".
