# Fire stations

The app's 637 Fire Service entries: 543 fire stations and 94 offices (Deputy Director, Assistant Director and Deputy Assistant Director of each district), in all 64 districts. Each has its number. They are shown under **Fire Service → Your local fire station**.

## Source

`source/fscd-<division>-division.pdf`: the Fire Service and Civil Defence (FSCD) lists of station and office numbers, one per division ("নতুন যোগাযোগ নাম্বার"), received 2026-11-05.

The PDFs use a legacy Bangla font, so their text cannot be copied. `source/fire_stations.txt` was typed from the page images. It has one line per row, numbers exactly as printed.

## Checks (`report.txt`)

- **Left blank until someone checks them: 15.** Each number was either misprinted or printed on two entries.
  - Wrong length:
    - Chattogram Deputy Director
    - Chattogram Zone-1
    - Agrabad
    - Brahmanbaria Deputy Assistant Director
    - Chandpur Deputy Assistant Director
    - Senbagh
    - Noapara
  - Old 7-digit Dhaka land line: Secretariat.
  - Out of series: Khulna Land-cum-River (01301…), Monirampur (01740…).
  - Same number as another entry:
    - Narayanganj Zone-2 (same as Dhaka Zone-2)
    - Khagrachhari Deputy Assistant Director (same as Chattogram Zone-3)
    - Kaliganj, Jhenaidah (same as Harinakunda)
    - Gaibandha (same as Kurigram)
    - BAU Mymensingh (same as Muktagachha)
  - The app shows these without a number ("Number being checked. Call 999 or 102 meanwhile.").
  - `report.txt` gives the probable number where the series makes it obvious. **Call to confirm, then enter it on the admin website.**
- **Kept, but outside the Fire Service's 01901-02xxxx series: 10.**
  - Kashimpur Mini, Naikhongchhari, North West (Sirajganj) and Phulbari (Kurigram) fire stations.
  - The Khulna foreman and control room.
  - The Mymensingh division officers and the Netrokona Deputy Assistant Director.
  - Worth a call.
- **Corrected:**
  - Kaptai is printed twice, under Chattogram Zone-3 and under Rangamati, with the same number. It is listed once, in Rangamati.
  - Kalyanpur (Dhaka) is printed twice; it is listed once.
  - The Barishal list prints Patuakhali's table under a second "পিরোজপুর জেলা" heading.

## Update

```bash
# 1. Edit source/fire_stations.txt, then → fire_stations_built.json + report.txt, and copy into the app
node build.mjs --install
# 2. Firestore (fire_stations/{id}) + packed copy for phones. Needs `firebase login` as an owner.
#    Entries an admin edited on the website (newer than the import, or marked checked) are kept.
node import_firestore.mjs
```

Small changes, such as one confirmed number, are quicker on the admin website: **Fire stations → search → Edit**. Phones get them within seconds. Release a new app version now and then so that the bundled offline copy is current too.
