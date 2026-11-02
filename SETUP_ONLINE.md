# Online setup (done — November 2026)

Everything online is **switched on** and runs on the free Firebase Spark plan:

| Piece | Where |
|---|---|
| Admin panel | <https://joruri-bd.web.app> — sign in with Google (see `admin/README.md`) |
| Public download page | <https://joruri-bd.web.app/download/> |
| APK files | GitHub releases in `Ashfaq1306/joruri-bd-releases` (public; holds only APKs) |
| Database rules | `firebase/firestore.rules` — live, tested by `firebase/rules-test` (see `firebase/README.md`) |
| Google sign-in | Enabled. SHA-1/SHA-256 registered for the shared release key and both developers' debug keys |

## On a new computer

1. Install Flutter, Node.js, `npm i -g firebase-tools`, GitHub CLI. Then `firebase login` and `gh auth login`.
2. Get `google-services.json`:
   ```bash
   firebase apps:sdkconfig ANDROID 1:309379921602:android:748b82e2b04dfbbf4bed5b --project joruri-bd \
     -o apps/mobile/android/app/google-services.json
   ```
3. For Google sign-in in **debug** builds on that computer, register its debug key once:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep -E 'SHA1|SHA256'
   firebase apps:android:sha:create 1:309379921602:android:748b82e2b04dfbbf4bed5b <SHA without colons> --project joruri-bd
   ```
4. To publish app versions you also need the release key: see `RELEASING.md`.

Never commit `google-services.json`, `key.properties` or `*.jks` (all in `.gitignore`).

## Troubleshooting

| Problem | Fix |
|---|---|
| App: "Google sign-in is not set up" | `google-services.json` missing or old: step 2 |
| App sign-in fails after choosing an account | The APK's signing key is not registered: step 3 (or build with the release key) |
| Admin panel: "Not an admin" | An owner adds your Gmail on the **Admins** page |
| Build: "Java version incompatible with Gradle" | Fixed: the project uses Gradle 9.3.1 / AGP 9.1 (works with Java 21 and 25) |
