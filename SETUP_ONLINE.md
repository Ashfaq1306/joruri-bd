# Going online on Fedora Linux (Firebase Spark, free)

This guide connects Joruri BD to your Firebase project **joruri-bd** using only free features:

- **Google Sign-In** in the app (people who want to be listed as blood donors, and to see the live donor list).
- The **admin website** on Firebase Hosting, where you sign in with Google.
- **Hosting deployment only.**

> ### ⚠️ Firestore rules are NOT part of this guide
> Your live Firestore rules stay **locked** (everything denied). The proposed rules in
> `firebase/firestore.rules.PROPOSED-NOT-DEPLOYED` are **not deployed** and **must not be deployed while following this guide**.
> Nothing below changes rules: `firebase.json` contains **hosting only**, so `firebase deploy --only hosting` cannot touch them.
> Deploying rules is a separate decision, described only in `firebase/RULES_PROPOSAL.md`.
>
> Never run `firebase init` (it can rewrite `firebase.json` and rules files), and never use `--config firebase.rules-deploy.json` here.

While the rules are locked, everything still works offline from the data built into the app. Google sign-in works too. Online features say they are not available yet, and the admin website says "Database is locked".

Commands are Bash. `~/projects/joruri_bd` is used as the project folder; change it if yours is elsewhere.

---

## 1. Install the tools (once)

```bash
# Node.js and npm (for the Firebase command-line tool)
sudo dnf install -y nodejs npm

# Install global npm tools into your home folder (no sudo needed later)
npm config set prefix "$HOME/.local"
npm install -g firebase-tools
firebase --version            # should print a version number

# keytool (to read your Android signing fingerprints)
sudo dnf install -y java-21-openjdk-headless
keytool -help >/dev/null && echo "keytool OK"
```
If `firebase` is "command not found", run `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc`.

Sign the Firebase tool in to your Google account (the one that owns the project):
```bash
firebase login                # opens a browser; on a machine without one: firebase login --no-localhost
```

## 2. Check the project and plan

In <https://console.firebase.google.com> → **joruri-bd**:

- Bottom-left shows **Spark**. Stay on Spark: nothing here needs billing.
- **Firestore Database** already exists in **asia-south1**. Do **not** open the Rules tab and publish anything.

## 3. Turn on Google sign-in

**Build → Authentication → Sign-in method**:

1. **Google** → Enable → choose a project support email → **Save**.
2. Email/Password: leave it **off** unless you specifically want the email option on the admin website (see step 9B).
3. **Authentication → Settings → Authorized domains** should list `joruri-bd.firebaseapp.com`, `joruri-bd.web.app` and `localhost`. Add any that are missing.

## 4. Add your Android fingerprints (SHA-1 and SHA-256)

Google sign-in on Android only works for apps whose signing fingerprint is registered.

Your debug key is created the first time you build the app. Make sure it exists, then read it:
```bash
cd ~/projects/joruri_bd/apps/mobile
ls ~/.android/debug.keystore || flutter build apk --debug    # creates it if missing

keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep -E 'SHA1:|SHA256:'
```
Alternative (uses the project's Gradle setup):
```bash
cd ~/projects/joruri_bd/apps/mobile/android && ./gradlew signingReport | grep -E 'Variant|SHA1|SHA-256'
```

In Firebase: **Project settings (gear) → General → Your apps → Android app `bd.joruri.joruri_bd` → Add fingerprint** → paste the **SHA1**, then add the **SHA-256** as a second fingerprint.

Right now both debug and release builds are signed with this debug key, so these two are enough. If you later create your own release key or publish on Google Play, add those fingerprints too (Play Console shows the Play signing key's SHA-1/SHA-256).

## 5. Download the new `google-services.json`

After step 3 and step 4, Firebase adds the OAuth client the app needs. On the same **Your apps → Android** card click **google-services.json** to download it, then:
```bash
cp ~/Downloads/google-services.json ~/projects/joruri_bd/apps/mobile/android/app/google-services.json
grep -c '"client_type": 3' ~/projects/joruri_bd/apps/mobile/android/app/google-services.json
```
The `grep` must print **1 or more**. If it prints 0, step 3 or 4 is not finished yet; wait a minute and download again.

(`flutterfire configure` is **not** required: on Android the app reads its Firebase settings from `google-services.json`.)

## 6. Build and test sign-in in the app

```bash
cd ~/projects/joruri_bd/apps/mobile
flutter pub get
flutter run            # phone connected by USB with USB debugging on
```
In the app: **Settings → My profile → Sign in with Google**.
- With the rules still locked, sign-in succeeds and the card then says **"The online list is not open yet"**. That is expected.
- If the app says **"Google sign-in is not set up for this app yet"**, the Web client ID is missing: redo step 5, or pass it directly. You find it at Authentication → Sign-in method → Google → **Web SDK configuration → Web client ID**:
  ```bash
  flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
  ```

## 7. Configure the admin website

1. **Project settings → General → Your apps → Add app → Web (`</>`)** → nickname `admin` → **Register app** (do **not** tick "Also set up Firebase Hosting"; the project already has its hosting config).
2. It shows a `firebaseConfig = { … }` block. Copy each value into `admin/firebase-config.js`, replacing every `PASTE_…`:
   ```bash
   nano ~/projects/joruri_bd/admin/firebase-config.js      # or any editor
   ```
   These values are not secret: they identify the project; access is controlled by Authentication and the rules.

Try it on your own computer **before** deploying anything:
```bash
cd ~/projects/joruri_bd
python3 -m http.server 5000 --directory admin
```
Open <http://localhost:5000> → **Sign in with Google**. With the locked rules you will see **"Database is locked"** and your **User UID** (keep it for step 9). Press `Ctrl+C` in the terminal to stop.

## 8. Deploy the website (hosting only)

From the top project folder (the one containing `firebase.json`):
```bash
cd ~/projects/joruri_bd
cat firebase.json                    # must contain only "hosting"
firebase use --add                   # choose joruri-bd, alias: default (creates .firebaserc)
firebase deploy --only hosting
```
The website is now at **https://joruri-bd.web.app**. This command deploys the `admin/` folder and **nothing else**: no rules, no indexes, no data.

To update the website later, run the same `firebase deploy --only hosting`.

## 9. Make yourself an admin

Signing in never makes anyone an admin. An account is an admin **only** if its UID is a document in the `admins` collection, and only you can create that, in the Firebase console. No app or website user can write `admins`.

### 9A. Recommended: your Google account

1. On the website (or at <http://localhost:5000>), **Sign in with Google** and copy the **User UID** shown.
   (Using the same Google account in the app gives the same UID.)
2. Console → **Firestore Database → Data → Start collection** → Collection ID `admins` → **Document ID = your UID** → add field `role`, type *string*, value `super` → **Save**.

Adding this document in the console does **not** change the rules. Your Google account's own 2-Step Verification now protects admin access: turn it on at <https://myaccount.google.com/security> if it is not on already.

### 9B. Optional: email and password instead

Only if you do not want to use a Google account on the website:
1. Authentication → Sign-in method → enable **Email/Password**.
2. Authentication → **Users → Add user** → email and a strong, unique password → copy the new **User UID**.
3. Add the `admins/<UID>` document exactly as in 9A.
4. On the website: **Use email and password instead**.

Use one method per email address; do not create an email/password user for the same address as your Google account.

### What you will see

| Live rules | Website after signing in |
|---|---|
| Locked (now) | **"Database is locked"** + your UID. Expected. The website cannot read anything until rules allow admins. |
| Proposed rules deployed (your later decision, `firebase/RULES_PROPOSAL.md`) | Admin listed → dashboard. Not listed → **"Not an admin"** + UID. |

## 10. What works while the rules are locked

| Feature | Status |
|---|---|
| SOS, emergency numbers, guides, toolkit, hospitals, pharmacies, blood search | ✅ from data built into the app |
| Google sign-in (app and website) | ✅ |
| Saving your profile | ✅ on the phone; online copy says "not open yet" and retries automatically later |
| Live donor list, content updates from the website, admin editing | ⏸ waits for the rules decision |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| App: "Google sign-in is not set up for this app yet" | Steps 3–5; or the `--dart-define=GOOGLE_WEB_CLIENT_ID=…` option in step 6 |
| App sign-in fails right after choosing an account | Fingerprint missing or wrong: repeat step 4 for the key that signed the APK you installed, then step 5 |
| Website: "This website address is not in … Authorized domains" | Step 3.3 |
| Website: "Almost ready" | `admin/firebase-config.js` still has `PASTE_…` values (step 7) |
| Website: "Database is locked" | Expected with locked rules |
| `firebase: command not found` | PATH line in step 1 |
| `firebase deploy` mentions firestore | Stop. You used the wrong config. `firebase.json` must contain only `hosting`; never pass `--config firebase.rules-deploy.json` while following this guide |
