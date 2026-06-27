#!/usr/bin/env bash
# Build a SIGNED ad-hoc IPA from a distribution certificate (.p12) + ad-hoc
# provisioning profile (.mobileprovision) committed under ios/signing/ — no
# fastlane `match`, no separate signing repo. macOS only.
#
# Required:
#   - ios/signing/*.p12              Apple Distribution cert exported WITH its
#                                    private key, protected by a password
#   - ios/signing/*.mobileprovision  ad-hoc profile for the app id, including
#                                    your test devices' UDIDs
#   - env IOS_P12_PASSWORD           the password that protects the .p12
#
# Output: build/ios/ipa/*.ipa (signed, installable OTA on the profile's devices).
set -euo pipefail

SIGN_DIR="ios/signing"
P12="$(ls "${SIGN_DIR}"/*.p12 2>/dev/null | head -1 || true)"
PROFILE="$(ls "${SIGN_DIR}"/*.mobileprovision 2>/dev/null | head -1 || true)"
: "${IOS_P12_PASSWORD:?IOS_P12_PASSWORD is required}"
[ -n "${P12}" ]     || { echo "::error::No .p12 found in ${SIGN_DIR}"; exit 1; }
[ -n "${PROFILE}" ] || { echo "::error::No .mobileprovision found in ${SIGN_DIR}"; exit 1; }
echo "Cert: ${P12}"
echo "Profile: ${PROFILE}"

# 1) Create a dedicated keychain and import the distribution cert into it.
KEYCHAIN="${RUNNER_TEMP:-/tmp}/zoonze-signing.keychain-db"
KCPW="ci-$(date +%s 2>/dev/null || echo pw)-$$"
security create-keychain -p "${KCPW}" "${KEYCHAIN}"
security set-keychain-settings -lut 21600 "${KEYCHAIN}"
security unlock-keychain -p "${KCPW}" "${KEYCHAIN}"
security import "${P12}" -k "${KEYCHAIN}" -P "${IOS_P12_PASSWORD}" \
  -T /usr/bin/codesign -T /usr/bin/security -f pkcs12
# Allow codesign to use the imported key without an interactive prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KCPW}" "${KEYCHAIN}" >/dev/null
# Add our keychain to the search list (keep the existing ones too).
security list-keychains -d user -s "${KEYCHAIN}" $(security list-keychains -d user | sed 's/["[:space:]]//g')

# 2) Read the profile's metadata (it's a CMS-signed plist).
PROFILE_PLIST="$(security cms -D -i "${PROFILE}")"
pb() { /usr/libexec/PlistBuddy -c "Print :$1" /dev/stdin <<<"${PROFILE_PLIST}" 2>/dev/null; }
PROFILE_UUID="$(pb UUID)"
PROFILE_NAME="$(pb Name)"
TEAM_ID="$(pb TeamIdentifier:0)"
APP_ID_FULL="$(pb Entitlements:application-identifier)"   # TEAMID.com.zoonze.shop
BUNDLE_ID="${APP_ID_FULL#*.}"
echo "Profile name='${PROFILE_NAME}' uuid=${PROFILE_UUID} team=${TEAM_ID} bundle=${BUNDLE_ID}"

# 3) Install the profile where Xcode looks for it.
PROFILES_DIR="${HOME}/Library/MobileDevice/Provisioning Profiles"
mkdir -p "${PROFILES_DIR}"
cp "${PROFILE}" "${PROFILES_DIR}/${PROFILE_UUID}.mobileprovision"

# 4) Generate ExportOptions for manual ad-hoc signing from the real values.
EXPORT_PLIST="${RUNNER_TEMP:-/tmp}/ExportOptions-AdHoc.plist"
cat > "${EXPORT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>ad-hoc</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>provisioningProfiles</key><dict>
    <key>${BUNDLE_ID}</key><string>${PROFILE_NAME}</string>
  </dict>
  <key>uploadSymbols</key><true/>
  <key>thinning</key><string>&lt;none&gt;</string>
</dict></plist>
PLIST

# 5) Build the signed IPA.
#
# We deliberately do NOT use `flutter build ipa` here. That wrapper runs the
# `xcodebuild archive` phase using the *project's* signing settings — and the
# committed Runner target is CODE_SIGN_STYLE=Automatic (correct for local dev
# and the App Store / fastlane match path). On a CI runner with no Apple ID,
# automatic signing can't provision and the archive fails with "No development
# certificates available", regardless of the export-options plist (which only
# governs the later export step).
#
# Instead: generate the Flutter build config, then archive + export with
# xcodebuild directly, forcing MANUAL signing via command-line build settings
# (highest precedence — overrides the project's Automatic style without editing
# any committed file). All values come from the profile we parsed above.
ARCHIVE="${RUNNER_TEMP:-/tmp}/Runner.xcarchive"
rm -rf "${ARCHIVE}"

# 5a) Prepare Generated.xcconfig (entrypoint + dart-defines) without building.
# --no-codesign is required: even in --config-only mode, `flutter build ios`
# runs its code-signing identity check for a device release build and aborts
# ("No valid code signing certificates were found") before writing the config.
# We only need the config here; signing is handled by the xcodebuild archive
# below. --no-codesign disables that check and does NOT persist any
# signing-disable flag into Generated.xcconfig, so the archive still signs.
flutter build ios --release --config-only --no-codesign \
  -t lib/main_prod.dart \
  --dart-define-from-file=config/prod.json

# 5b) Archive WITHOUT code signing.
# Command-line build settings (KEY=VALUE) apply to EVERY target in the
# workspace, so pinning a PROVISIONING_PROFILE_SPECIFIER here makes the archive
# fail — the framework/library targets (Firebase, GoogleUtilities, plugins,
# Pods) "do not support provisioning profiles". Instead archive unsigned and do
# all signing at the export step below, where the export-options plist scopes
# the profile to the app's bundle id only.
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

# 5c) Export + sign the ad-hoc IPA. -exportArchive re-signs the app and its
# embedded frameworks with the distribution identity from the dedicated
# keychain, using the ad-hoc profile mapped to com.zoonze.shop in EXPORT_PLIST.
mkdir -p build/ios/ipa
xcodebuild -exportArchive \
  -archivePath "${ARCHIVE}" \
  -exportPath build/ios/ipa \
  -exportOptionsPlist "${EXPORT_PLIST}"

echo "✅ Signed ad-hoc IPA → $(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)"
