# Admin panel — https://joruri-bd.web.app

Plain web page (no build step) on Firebase Hosting. Sign in with your Google account; only accounts on the **Admins** page get in.

| Page | What it does | Reaches phones |
|---|---|---|
| Dashboard | Counts, a to-do list of missing data, **Send content to phones now** | — |
| Announcements | Notices on the app's home screen (info / warning / urgent), optional button (`https://…`, `tel:999`, or `app:/blood` to open a screen), optional date range | within seconds when online |
| App & updates | Latest app version + download links, minimum version, "show draft guides", "show unchecked numbers" | within seconds |
| Emergency numbers, Hospitals & tests, Pharmacies, Guides | Edit everything the app shows; untick **Show on phones** to hide without deleting | within seconds |
| Blood donors | Add donors who agreed to share their number; mark checked ✔ or hide | live, for signed-in app users |
| Admins | Owners add/remove admins by Gmail address (owner or editor) | — |
| Import & backup | Import the CSV templates in `apps/mobile/tool/` or the app's seed JSON; download a full JSON backup | as content |
| Activity log | Every change, who made it; cannot be edited | — |

Hospitals: 8,616 entries imported from the DGHS Facility Registry (IDs `dghs-<registry id>`). Edit any of them, add your own, or untick **Show on phones**. The list shows 300 rows at a time; use the search box.

Phones keep everything they downloaded, so the app works offline. A mistake that would remove every emergency number is ignored by the app (it keeps the previous list).

Deploy website changes: `firebase deploy --only hosting` from the repo root (or the release script with `--website-only`).
Security rules: `firebase/firestore.rules`, tested by `firebase/rules-test` (`npm install && npm test`, needs Java).
