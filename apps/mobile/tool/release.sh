#!/usr/bin/env bash
# Publishes a new app version for everyone.
#
#   cd apps/mobile
#   ./tool/release.sh "Faster blood search" "দ্রুত রক্তদাতা খোঁজা"
#   ./tool/release.sh --website-only     # only deploy the admin panel / download page
#
# 1. Raise the version in pubspec.yaml first (e.g. 1.0.0+10 -> 1.1.0+11).
#    The number after + must go up every release.
# 2. This script builds the signed APKs and publishes them as a GitHub
#    release in Ashfaq1306/joruri-bd-releases (free, public downloads;
#    Firebase's free plan does not allow APK files). The download links
#    ".../releases/latest/download/joruri-bd.apk" always point to the newest.
# 3. Then on the admin panel's "App & updates" page press "Use latest
#    release" and Save: every phone shows "Update available".
# Needs: flutter, gh (signed in, with access to the releases repo), firebase, node.
set -euo pipefail
mobile="$(cd "$(dirname "$0")/.." && pwd)"
root="$(cd "$mobile/../.." && pwd)"
repo="Ashfaq1306/joruri-bd-releases"

if [[ "${1:-}" != "--website-only" ]]; then
  notes="${1:-}"; notes_bn="${2:-}"
  if [[ ! -f "$mobile/android/key.properties" ]]; then
    echo "android/key.properties is missing. Releases must be signed with the shared Joruri release key (see RELEASING.md)." >&2
    exit 1
  fi
  ver="$(grep -E '^version:' "$mobile/pubspec.yaml" | awk '{print $2}')"
  name="${ver%%+*}"; code="${ver##*+}"; tag="v$name-build$code"
  echo "Building Joruri BD $name (build $code)..."
  (cd "$mobile" && flutter build apk --release --split-per-abi)
  out="$mobile/build/app/outputs/flutter-apk"; stage="$mobile/build/release-upload"
  mkdir -p "$stage"
  cp "$out/app-arm64-v8a-release.apk" "$stage/joruri-bd.apk"
  cp "$out/app-armeabi-v7a-release.apk" "$stage/joruri-bd-arm32.apk"
  NAME="$name" CODE="$code" NOTES="$notes" NOTES_BN="$notes_bn" APK="$stage/joruri-bd.apk" node -e '
    const e = process.env, fs = require("fs");
    const size = Math.round(fs.statSync(e.APK).size / 104857.6) / 10;
    const info = { versionName: e.NAME, versionCode: Number(e.CODE), sizeMb: size, notes: { en: e.NOTES, bn: e.NOTES_BN } };
    process.stdout.write(`Joruri BD ${e.NAME} (build ${e.CODE})\n\n${e.NOTES}\n\n${e.NOTES_BN}\n\n<!-- joruri ${JSON.stringify(info)} -->`);
  ' > "$stage/notes.md"
  echo "Publishing $tag to github.com/$repo ..."
  gh release create "$tag" "$stage/joruri-bd.apk" "$stage/joruri-bd-arm32.apk" \
    --repo "$repo" --title "Joruri BD $name" --notes-file "$stage/notes.md" --latest
fi

(cd "$root" && firebase deploy --only hosting --project joruri-bd)
echo
echo "Done. Download page: https://joruri-bd.web.app/download/"
[[ "${1:-}" == "--website-only" ]] || echo 'Last step: open https://joruri-bd.web.app/#app , press "Use latest release", then Save. Every phone is then told to update.'
