# Releasing a new app version

Content (emergency numbers, hospitals, pharmacies, guides, announcements, donors) is changed on the **admin panel** and reaches phones by itself — no new app needed. A new app version is only needed when the **code** changes.

## One-time setup on a computer

1. Flutter, Firebase CLI (`npm i -g firebase-tools`, then `firebase login`) and GitHub CLI (`gh auth login`).
2. **The release signing key.** Every APK people install must be signed with the same key, or Android refuses to install it as an update. The key is **not in git**. Get these two files privately from Ashfaq (USB / private Drive — never commit or post them):
   - `joruri-release.jks`
   - `key.properties`
3. Put `key.properties` at `apps/mobile/android/key.properties` and change its `storeFile=` line to where you saved `joruri-release.jks`.
4. `apps/mobile/android/app/google-services.json`: download with
   `firebase apps:sdkconfig ANDROID 1:309379921602:android:748b82e2b04dfbbf4bed5b --project joruri-bd -o apps/mobile/android/app/google-services.json`
5. Publishing needs write access to `github.com/Ashfaq1306/joruri-bd-releases` (the public repo that holds only the APKs; Firebase's free plan does not allow hosting APK files).

If you lose the key there is no way to publish updates that install over the old app: keep at least two private copies.

## Each release

1. In `apps/mobile/pubspec.yaml` raise the version, e.g. `1.0.1+11` → `1.1.0+12`. The number after `+` **must go up** every time (and stay below 1000).
2. Run the tests: `cd apps/mobile && flutter analyze && flutter test`
3. Publish:
   ```bash
   cd apps/mobile
   ./tool/release.sh "What changed in English" "বাংলায় কী বদলেছে"          # Linux / macOS
   .\tool\release.ps1 -Notes "What changed" -NotesBn "কী বদলেছে"            # Windows
   ```
   This builds the signed APKs (64-bit and 32-bit), creates a GitHub release, and redeploys the admin website.
4. Open <https://joruri-bd.web.app/#app>, press **Use latest release**, then **Save**. Every phone running an older version now shows **Update available** (within seconds if online).

To force very old versions to update, set **Oldest build still allowed** on the same page; those phones see a red "Please update" card. SOS keeps working regardless.

## Links

- Download page to share: <https://joruri-bd.web.app/download/>
- Direct APK (always the newest): <https://github.com/Ashfaq1306/joruri-bd-releases/releases/latest/download/joruri-bd.apk>
- Website only (no new app): `./tool/release.sh --website-only` or `.\tool\release.ps1 -WebsiteOnly`

## Version codes

`flutter build apk --split-per-abi` adds 1000 × CPU code to the build number (arm64 = 2011 for build 11). The app strips this before comparing with the admin panel's number, so always enter the plain number (11). Always release split APKs: a non-split build has a lower code and cannot install over a split one.
