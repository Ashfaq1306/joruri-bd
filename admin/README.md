# Admin panel — https://joruri-bd.web.app

A plain web page (no build step) on Firebase Hosting. It works on a computer or a phone browser.

## Getting in

1. Open **https://joruri-bd.web.app** and press **Sign in with Google**.
2. Only Google accounts on the **Admins** page get in. Today these are the two owners, `ashfaqur87654@gmail.com` and `rhmugdho5@gmail.com`. Anyone else is refused, even after signing in.
3. To let someone help, an **owner** opens **Admins** and adds their Gmail address:
   - **Editor** can change all content and donors.
   - **Owner** can also add and remove admins.

## How changes reach phones

Every **Save** goes to the database and raises the content version.

- Phones that are online get the change **within seconds**. Offline phones get it the next time they connect.
- Phones keep a copy, so the app also works without internet.
- No new app version is needed for content, only for code changes.
- If a phone seems behind, press **Dashboard → ⟳ Send content to phones now**.
- To hide something without deleting it, untick **Show on phones**. Hidden rows show grey in the list.

## Every page

| Page | What you can do | Reaches phones |
|---|---|---|
| **Dashboard** | Counts, a **To do** list of missing or doubtful data (click a line to go there), **Send content to phones now** | — |
| **Announcements** | Notice on the app's home screen. Choose info, warning or urgent. Optional button: `https://…`, `tel:999`, or `app:/blood` to open a screen. Optional start and end dates | seconds |
| **App & updates** | Newest app version and download links. **Use latest release** fills them from GitHub; the release script does this for you. Also: **Oldest build still allowed** (forces a red "Please update" card), show draft guides, show unchecked numbers | seconds |
| **Emergency numbers** | National numbers (999, 102 …): category, Bangla and English text, "checked" status and source | seconds |
| **Hospitals & tests** | About 8,600 hospitals from the DGHS registry. Edit phone, address and tests with prices, or add your own. The list shows 300 rows; use **Search** | seconds |
| **Pharmacies** | All 117,274 DGDA-licensed pharmacies built into the app: choose a district in **Find a shop in the DGDA register**, then **Edit** (add a phone number, mark open 24 hours) or **Hide** (closed, wrong). **+ Add** a shop that is not in the register | seconds |
| **Medicines & prices** | All 38,834 medicines of the DGDA price list built into the app: **Find a medicine**, then **Edit** the price or details, or **Hide** it. **+ Add** a medicine DGDA does not list | seconds |
| **Police stations** | 630 thanas with the OC's mobile. Edit when an OC number changes | seconds |
| **Fire stations** | 543 fire stations and 94 Fire Service offices with their numbers. Rows marked **⚠ Check** have no number yet (see below) | seconds |
| **Guides** | First-aid and disaster guides in Bangla and English: steps, warnings, review status | seconds |
| **Blood donors** | Add donors who agreed to share their number, mark them checked ✔, or hide them. Donors who signed up in the app edit their own details | live, for signed-in app users |
| **Admins** | Owners add or remove admins | — |
| **Import & backup** | Import the CSV templates (`apps/mobile/tool/`) or the app's seed JSON files; **⭳ Download backup** saves everything as one JSON file | as content |
| **Activity log** | Every change: who made it and when. It cannot be edited | — |

## Changing something

1. Click the page in the menu on the left. On a phone, open the menu first.
2. Type in **Search…** (any word: a name, a district, part of a number).
3. Click **Edit** on the row, change the fields, then **Save**. Or click **+ Add** for a new entry, or **Delete** to remove one; Delete asks first.
4. A field you empty is removed. Phone numbers can be typed in any form, including Bangla digits (০১৯০১-…). They are stored as `+8801…`.

## Medicines and pharmacies built into the app

The DGDA medicine price list and the DGDA pharmacy register are built into the app, so they work offline. The admin panel does not copy them into the database; it stores only **your changes**, and phones apply them on top of the built-in lists.

- **Medicines & prices → Find a medicine in the DGDA list**: type a brand or generic name (e.g. `napa`, `paracetamol`).
  - **Edit** opens the entry. Change what is wrong; prices go one per line as `pack | price per unit`, for example `10 x 10 in Blister Pack | 1.20`. Save. The app now shows your version, marked "Checked and updated by the Joruri BD team".
  - **Hide** removes the entry from the app; **Show again** brings it back.
  - **+ Add** adds a medicine that DGDA does not list.
- **Pharmacies → Find a shop in the DGDA register**: choose the district, type part of the name, area or licence number.
  - **Edit** lets you add the phone number, mark it open 24 hours or fix the address. Save.
  - **Hide** removes a closed or wrong shop from the app; **Show again** brings it back.
- Everything you changed is listed under **Your changes and additions**. **Delete** there undoes the change: the app goes back to the DGDA entry as it was.

## Fire stations: the 15 numbers to check

The Fire Service lists had misprints: numbers with 12 digits, an old Dhaka land line, and the same number printed on two stations. Those 15 rows have no number in the app. People see "Number being checked. Call 999 or 102 meanwhile" instead of dialling a guess.

To fix one:

1. **Fire stations**, then search `⚠`.
2. The Check column says what was wrong and, where it is clear, the probable number.
3. Call to confirm.
4. **Edit**, type the number, and tick **Checked by a person**. The ⚠ note clears by itself when you save a number.

The full list is in `tools/fire-import/report.txt`.

## Deploying changes to this website

`firebase deploy --only hosting` from the repo root, or `.\tool\release.ps1 -WebsiteOnly`. Before each deploy, `tools/admin-data/copy.mjs` copies the built-in DGDA lists to `admin/data/` (not kept in git) for the Medicines and Pharmacies pages.

Security rules are in `firebase/firestore.rules` and tested by `firebase/rules-test` (`npm install && npm test`; needs Java).
