# Police stations and emergency numbers

The app's 630 police stations (thanas), each with the officer in charge's (OC) mobile number, and the national emergency numbers.

## Sources

| File | What it is | Used for |
| --- | --- | --- |
| `source/thana-services.pdf` | RAB's list of police-station OCs (rab.gov.bd/contact-us, accessed 20-10-2024; 01320 series) | OC number of every thana |
| `source/dmp_find_your_local_police.html` | DMP website, "Find your local police" (downloaded 2026-11-04) | Address and e-mail of DMP thanas |

**Checked:** the PDF's 18 Cumilla numbers match an independent Cumilla list exactly (OC 01320-113996 Kotwali … 01320-114438 Lalmai).

**Not used:**
- `OC_Contact_List.pdf` (old 01713 series): the same number on several thanas (Dhanmondi, Shahbag and New Market all 01713373126), 10-digit numbers, rows out of line.
- DMP website phone numbers: duty-officer cells are 011 numbers (Citycell, closed in 2016), land lines are pre-2018 7-digit Dhaka numbers, OC cells are the old 01713 series.

**Left out until someone checks them** (out of sequence in the PDF, probably misprinted): Rajpur, Jhalokati (`01320-154123`) and Shashibhushan, Bhola (`01320-152333`). Not in the PDF at all: Brahmanbaria Sadar and Chandpur Sadar. Add them on the admin panel (Police stations → + Add) once confirmed.

## How the list is built

The PDF's text comes out of line (the number column is shifted by two rows), so `extract_pdf.py` reads each row by its position on the page. `names.mjs` holds what the PDF does not say: the district of each number block (`01320-089…` = Dhaka district, `090` = Narayanganj …; each district's Sadar station sits at the end of the previous block), standard English names and Bangla names. Other Bangla names come from the DGHS Upazila Health Complexes (`apps/mobile/assets/seed/hospitals.json`).

```bash
# 1. PDF → thana_rows.json (needs PyMuPDF: pip install pymupdf)
python extract_pdf.py source/thana-services.pdf thana_rows.json
# 2. → police_stations_built.json + report.txt; --install copies it into the app
node build.mjs --install
# 3. Firestore (police_stations/{id}) + packed copy for phones. Needs `firebase login` as an owner.
#    Stations an admin edited on the website (newer than the import, or marked checked) are kept.
node import_firestore.mjs
# National emergency numbers (edit the list in the file):
node emergency_numbers.mjs --publish
```

Then release a new app version so the bundled (offline) copy is current too. Phones that are online get the Firestore copy within seconds anyway.
