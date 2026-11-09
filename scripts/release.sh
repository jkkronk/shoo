#!/usr/bin/env bash
# scripts/release.sh — archive, export and (optionally) upload an App Store build.
#
#   bash scripts/release.sh            # archive + export build/export/Shoo.pkg, then validate
#   bash scripts/release.sh --upload   # same, then upload to App Store Connect / TestFlight
#
# Requirements (one-time, on your Mac):
#   * Xcode 26 or later, signed in to the Apple Developer account for team 8HW5ABG4L2
#     (Xcode → Settings → Accounts). Automatic signing then creates the Apple Distribution
#     and Mac Installer Distribution certificates and the Mac App Store profile on demand.
#   * The app record must exist in App Store Connect with bundle ID io.github.jkkronk.shoo.
#   * For --upload without an interactive Xcode login, an App Store Connect API key:
#       export ASC_KEY_ID=ABC123DEFG ASC_ISSUER_ID=xxxxxxxx-... ASC_KEY_PATH=~/.private_keys/AuthKey_ABC123DEFG.p8
#     (Users and Access → Integrations → App Store Connect API; role "App Manager" is enough.)
#
# Every upload needs a higher CURRENT_PROJECT_VERSION than the last one. Bump it in
# project.yml first (or run `make bump`).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="Shoo.xcodeproj"
SCHEME="Shoo"
ARCHIVE="build/Shoo.xcarchive"
EXPORT_DIR="build/export"
EXPORT_OPTIONS="fastlane/ExportOptions.plist"
UPLOAD=false
[[ "${1:-}" == "--upload" ]] && UPLOAD=true

VERSION="$(sed -n 's/.*MARKETING_VERSION:[[:space:]]*"\{0,1\}\([0-9.]*\)"\{0,1\}.*/\1/p' project.yml | head -1)"
BUILD="$(sed -n 's/.*CURRENT_PROJECT_VERSION:[[:space:]]*"\{0,1\}\([0-9]*\)"\{0,1\}.*/\1/p' project.yml | head -1)"
echo "== Shoo ${VERSION} (${BUILD}) =="

AUTH_ARGS=()
if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]]; then
  AUTH_ARGS=(-authenticationKeyPath "${ASC_KEY_PATH/#\~/$HOME}" \
             -authenticationKeyID "$ASC_KEY_ID" \
             -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

echo "== Generating project =="
xcodegen generate

echo "== Archiving (Release, automatic signing) =="
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
  archive

echo "== Exporting App Store package =="
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}

PKG="$(ls "$EXPORT_DIR"/*.pkg | head -1)"
# An App Store export produces only the .pkg. Inspect the app inside the archive for
# plist/entitlement checks, and expand the .pkg to check the distribution signature.
ARCHIVE_APP="$ARCHIVE/Products/Applications/Shoo.app"
EXPANDED="build/pkg-contents"
rm -rf "$EXPANDED"
pkgutil --expand-full "$PKG" "$EXPANDED"
PKG_APP="$(find "$EXPANDED" -name 'Shoo.app' -maxdepth 4 -type d | head -1)"
echo
echo "== Pre-submission checks (docs/APP_STORE_READINESS.md, Appendix B) =="
echo "-- entitlements (expect only app-sandbox + device.camera):"
codesign -d --entitlements - "$PKG_APP" 2>/dev/null | grep -E 'com\.apple\.security' || true
echo "-- app signing authority (expect Apple Distribution / 3rd Party Mac Developer Application):"
codesign -dv --verbose=4 "$PKG_APP" 2>&1 | grep -E '^(Authority|TeamIdentifier|Identifier)=' || true
echo "-- installer signature (expect 3rd Party Mac Developer Installer):"
pkgutil --check-signature "$PKG" | head -4 || true
echo "-- category / version:"
plutil -p "$ARCHIVE_APP/Contents/Info.plist" | grep -E 'LSApplicationCategoryType|CFBundleShortVersionString|CFBundleVersion|CFBundleIdentifier' || true
echo "-- privacy manifest:"
ls "$ARCHIVE_APP/Contents/Resources/PrivacyInfo.xcprivacy"

if [[ "$UPLOAD" == true ]]; then
  echo
  echo "== Uploading to App Store Connect =="
  UPLOAD_OPTIONS="build/ExportOptions-upload.plist"
  cp "$EXPORT_OPTIONS" "$UPLOAD_OPTIONS"
  /usr/libexec/PlistBuddy -c "Set :destination upload" "$UPLOAD_OPTIONS"
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$UPLOAD_OPTIONS" \
    -exportPath "$EXPORT_DIR/upload" \
    -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}
  echo "Uploaded. Processing takes a few minutes; then it appears under TestFlight in App Store Connect."
else
  echo
  echo "Exported: $PKG"
  echo "Next: bash scripts/release.sh --upload   (or Xcode → Window → Organizer → Distribute App)"
fi
