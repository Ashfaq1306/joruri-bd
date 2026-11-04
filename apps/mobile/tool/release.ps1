# Publishes a new app version for everyone.
#
#   cd apps/mobile
#   .\tool\release.ps1 -Notes "Faster blood search" -NotesBn "দ্রুত রক্তদাতা খোঁজা"
#   .\tool\release.ps1 -WebsiteOnly     # only deploy the admin panel / download page
#
# 1. Raise the version in pubspec.yaml first (e.g. 1.0.0+10 -> 1.1.0+11).
#    The number after + must go up every release.
# 2. This script builds the signed APKs and publishes them as a GitHub
#    release in Ashfaq1306/joruri-bd, the public project repository (free downloads;
#    Firebase's free plan does not allow APK files). The download links
#    ".../releases/latest/download/joruri-bd.apk" always point to the newest.
# 3. It then tells every phone (tools/announce_release.mjs, same as "Use
#    latest release" + Save on the admin panel): "Update available".
# Needs: flutter, gh (signed in, with access to the releases repo), firebase.
param(
  [string]$Notes = '',
  [string]$NotesBn = '',
  [switch]$WebsiteOnly
)
$ErrorActionPreference = 'Stop'
$mobile = Split-Path -Parent $PSScriptRoot
$root = Resolve-Path (Join-Path $mobile '..\..')
$repo = 'Ashfaq1306/joruri-bd'

# Native tools write warnings to stderr; judge them by exit code only.
function Run([scriptblock]$cmd, [string]$what) {
  $ErrorActionPreference = 'Continue'
  & $cmd
  if ($LASTEXITCODE -ne 0) { throw "$what failed" }
}

if (-not $WebsiteOnly) {
  if (-not (Test-Path (Join-Path $mobile 'android\key.properties'))) {
    throw 'android/key.properties is missing. Releases must be signed with the shared Joruri release key, otherwise phones cannot install them as an update. See RELEASING.md.'
  }
  $line = (Select-String -Path (Join-Path $mobile 'pubspec.yaml') -Pattern '^version:\s*(\S+)\+(\d+)').Matches[0]
  $name = $line.Groups[1].Value; $code = [int]$line.Groups[2].Value
  $tag = "v$name-build$code"
  Write-Host "Building Joruri BD $name (build $code)..." -ForegroundColor Green
  Push-Location $mobile
  try { Run { flutter build apk --release --split-per-abi } 'flutter build' } finally { Pop-Location }

  $out = Join-Path $mobile 'build\app\outputs\flutter-apk'
  $stage = Join-Path $mobile 'build\release-upload'
  New-Item -ItemType Directory -Force $stage | Out-Null
  Copy-Item (Join-Path $out 'app-arm64-v8a-release.apk') (Join-Path $stage 'joruri-bd.apk') -Force
  Copy-Item (Join-Path $out 'app-armeabi-v7a-release.apk') (Join-Path $stage 'joruri-bd-arm32.apk') -Force
  # Google sign-in needs the Web client ID inside the APK (see res/raw/keep.xml).
  $sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
  $aapt = Get-ChildItem (Join-Path $sdk 'build-tools') -Recurse -Filter aapt2.exe -ErrorAction SilentlyContinue | Sort-Object FullName | Select-Object -Last 1
  if ($aapt) {
    foreach ($apk in 'joruri-bd.apk', 'joruri-bd-arm32.apk') {
      $res = & $aapt.FullName dump resources (Join-Path $stage $apk) | Out-String
      if ($res -notmatch 'string/default_web_client_id') { throw "$apk has no default_web_client_id: Google sign-in would fail. Is Google sign-in enabled in Firebase and google-services.json current?" }
    }
  } else { Write-Warning 'aapt2 not found: could not check the APK for the Google sign-in client ID.' }
  $size = [math]::Round((Get-Item (Join-Path $stage 'joruri-bd.apk')).Length / 1MB, 1)
  $info = [ordered]@{ versionName = $name; versionCode = $code; sizeMb = $size; notes = [ordered]@{ en = $Notes; bn = $NotesBn } }
  $json = $info | ConvertTo-Json -Compress
  $body = "Joruri BD $name (build $code)`n`n$Notes`n`n$NotesBn`n`n<!-- joruri $json -->"
  $bodyFile = Join-Path $stage 'notes.md'
  [IO.File]::WriteAllText($bodyFile, $body, [Text.UTF8Encoding]::new($false))

  Write-Host "Publishing $tag to github.com/$repo ..." -ForegroundColor Green
  Run { gh release create $tag (Join-Path $stage 'joruri-bd.apk') (Join-Path $stage 'joruri-bd-arm32.apk') `
      --repo $repo --title "Joruri BD $name" --notes-file $bodyFile --latest } 'gh release create'
}

Push-Location $root
try {
  Run { firebase deploy --only hosting --project joruri-bd } 'firebase deploy'
  # Tell every phone about the new version (was a manual admin-panel step).
  if (-not $WebsiteOnly) { Run { node tools/announce_release.mjs } 'announce release' }
} finally { Pop-Location }
Write-Host ''
Write-Host 'Done. Download page: https://joruri-bd.web.app/download/' -ForegroundColor Green
if (-not $WebsiteOnly) {
  Write-Host 'Every phone with an older version now shows "Update available" (check: https://joruri-bd.web.app/#app).' -ForegroundColor Green
}
