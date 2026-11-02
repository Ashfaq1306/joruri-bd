# Admin website

Plain web page (no build step), hosted on Firebase Hosting. Admins sign in with Google (recommended) or email/password; only UIDs listed in the `admins` collection (added by hand in the Firebase console) can change anything.

Setup and **hosting-only** deployment: ../SETUP_ONLINE.md, steps 7–9. This never deploys Firestore rules.
