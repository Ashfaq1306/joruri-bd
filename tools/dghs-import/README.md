# Hospital data from the DGHS Facility Registry

The app's 8,616 hospitals, clinics and blood banks come from the official **DGHS Facility Registry** (<https://hris.mohfw.gov.bd/public/facility-registry>), downloaded 2026-11-03. Test prices come from the **Ministry of Health government user-fee chart** (circular re-issued 09-04-2023); see `apps/mobile/assets/seed/fee_charts.json`.

To refresh the list (e.g. once a year). Run from this folder; it writes its working files here (they are git-ignored):

```bash
node fetch_lists.mjs      # ~20 requests: every hospital-type facility → dghs_list.json
node fetch_profiles.mjs   # one request per facility, 3 at a time (~45 min, resumable) → profiles.jsonl
node build.mjs            # → hospitals_built.json (+ report)
node import_firestore.mjs # writes hospitals/{dghs-<id>} and the packed snapshots; needs `firebase login` as a project owner
```
Then copy the result into the app's bundled copy (see the commit that added this folder) and release a new version.

What `build.mjs` does: keeps the registry's name (English + Bangla), type, district, upazila, address, phones, email, website, map position and beds; drops placeholder numbers (`0000000`, `01711111111`), local numbers without an area code, and map positions shared by more than 3 facilities (defaults, not real spots). Emergency/24-hour flags are set only for types that run 24-hour emergency departments by government policy (medical college, district, upazila and 10–50-bed hospitals, trauma centres). Government hospitals get the shared fee chart (`feeChart`); CT/MRI only for medical college, postgraduate and specialised hospitals. Private hospitals get **no prices**: there is no official source. Admin edits on the website win over a re-import only if you skip re-importing those IDs.

Be polite to the DGHS server: keep the 3-worker limit and delays.
