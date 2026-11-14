# Disaster alert watcher

Runs every 10 minutes on GitHub Actions (`.github/workflows/alerts.yml`).

1. Reads the **Bangladesh Meteorological Department** CAP feed
   (`https://cap.bmd.gov.bd/api/cap/rss.xml`, each warning in English and
   Bangla with its area as polygons) and the **USGS** earthquake list for
   Bangladesh and the seismic belts around it.
2. Writes the active alerts to Firestore `meta/alerts` → `official` (JSON),
   only when the list changed. Every open app follows this document live.
   The admin website writes the team's own alerts to `meta/alerts` → `team`.
3. Sends each new alert of level *watch* or higher (official or team, at most
   12 hours old; earthquakes 3 hours) as an FCM notification to the topics of
   the districts it covers, in both languages: `alerts-bn-<district>`,
   `alerts-en-<district>`, plus `alerts-bn-all` / `alerts-en-all`.
   `meta/alertsPushed` remembers what was sent.

The parsing and the district matching are in `packages/core/lib/src/alerts`
(the app uses the same code when it reads BMD and USGS itself).

## Run by hand

```bash
cd tools/alerts
dart pub get
dart run bin/watch.dart --dry-run    # print only, signed in with your `firebase login`
dart run bin/watch.dart --no-push    # update meta/alerts, no notifications
```

On GitHub: Actions → *Disaster alerts* → **Run workflow** checks immediately.

## Sign-in (no keys)

`setup_github_access.mjs` (run once by a project owner) created:

- service account `alerts-watcher@joruri-bd.iam.gserviceaccount.com` with only
  `roles/datastore.user` and `roles/firebasecloudmessaging.admin`;
- workload identity pool `github`, provider `joruri-bd`, accepting GitHub's
  OIDC tokens **only from the repository `Ashfaq1306/joruri-bd`**.

No key file exists. To revoke: delete the provider or the service account in
the Google Cloud console (IAM → Workload Identity Federation / Service accounts).

## District areas

`build_district_points.mjs` regenerates `packages/core/lib/src/geo/bd_district_points.dart`
(centre + up to 12 points per district, from the coordinates of DGHS-registered
health facilities). A warning covers a district when one of its points is
inside the warning's polygon or the district is named in the area/instruction.

## Limits

- Earthquakes cannot be predicted. USGS lists a quake minutes after it
  happens; the app explains how to keep **Android Earthquake Alerts** on,
  the only warning that can arrive seconds before shaking.
- BMD's feed covers what BMD issues (cyclones, heavy rain, heat/cold waves,
  storms, fog). River flood warnings (FFWC) have no public feed: the team
  enters them on the admin website.
- GitHub may delay scheduled runs by a few minutes at busy times. The
  workflow re-enables itself daily so GitHub does not pause it after 60 days
  without commits.
