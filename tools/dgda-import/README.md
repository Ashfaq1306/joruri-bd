# Pharmacies and medicine prices from DGDA

Both lists come from the **Directorate General of Drug Administration (DGDA)**, downloaded 2026-11-03.

| Data | Source | In the app |
| --- | --- | --- |
| Licensed retail pharmacies | DGDA → Pharmacies → *Allopathic Retail Pharmacy* (<https://dgdagov.info/index.php/pharmacies/allopathic-retail-pharmacy>), 169,461 rows | `apps/mobile/assets/seed/pharmacies/<districtId>.json`, one file per district (117,274 shops) |
| Medicine prices | DGDA medicine price search (<http://180.211.137.202:9310/Allopathic/>, linked as "Search Price" on dgdagov.info): *Medicine Information* list + one *Medicine Price Detail* page per brand | `apps/mobile/assets/seed/medicines.json` |

## Refresh (e.g. every 3–6 months)

Run from this folder. Working files are git-ignored.

```bash
node fetch_pharmacies.mjs   # ~35 requests of 5,000 rows, ~2 min → pharmacies_raw.jsonl (resumable)
node fetch_medicines.mjs    # list + ~41,000 price pages, 3 at a time, ~2 h → prices.jsonl (resumable)
node build_pharmacies.mjs   # → ../../apps/mobile/assets/seed/pharmacies/*.json + pharmacies_report.txt
node build_medicines.mjs    # → ../../apps/mobile/assets/seed/medicines.json + medicines_report.txt
```
Set `DOWNLOADED_ON=YYYY-MM-DD` for the build scripts if you build on a later day than the download. Then run the app tests and release a new version (`RELEASING.md`).

## What the build scripts keep and drop

**Pharmacies** (`build_pharmacies.mjs`)
- Kept: shop name, district, upazila, address, phone, licence number, licence end date.
- **Never kept: pharmacist name, proprietor name, national ID** (the register has them; they are dropped while downloading and never written to disk).
- Shops whose licence ended more than 5 years before the download are left out (51,880 rows): the online register lags behind renewals (most Dhaka city shops show old dates), but a licence that ran out long ago usually means the shop closed. The app shows "Licence valid until …" or "Licence expired … (per DGDA list)" and lists valid shops first.
- Phone: the first valid Bangladeshi number (mobile `01[3-9]` + 8 digits, or landline with area code); placeholders like `00000000000` are dropped. Only ~22,000 shops have a number in the register; the others get a **Directions** button (Google Maps search by name and address).
- One row the DGDA server returns as broken JSON is skipped.

**Medicines** (`build_medicines.mjs`)
- Kept: brand, generic, strength, dosage form, company, DAR (registration) number, every pack size with its unit price (taka).
- Left out: veterinary products (DAR class `-077` or "Vet" in the name) and raw materials / bulk (kg, litre).
- Brands whose price page has no price are kept and shown as "DGDA has not published a price"; nothing is estimated.

Pharmacies and medicines are **built into the app**, not stored in Firestore: 117,000 shops would cost every phone a ~20 MB download on each change on the free plan. Pharmacies the team adds on the admin website are shown on top, and an admin entry with the same DGDA licence number replaces the built-in one.

Be polite to the DGDA servers: keep the 3-worker limit and the delays.

Note (2026-11-03): pages on dgdagov.info contain hidden casino spam links injected into the site, which suggests the site was compromised. The data endpoints used here return plain JSON/HTML tables; nothing from those pages is executed. Consider telling DGDA.
