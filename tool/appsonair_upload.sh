#!/usr/bin/env bash
# Upload builds to AppsOnAir via the official OTA CLI (@appsonair/appsonair-cli).
# Docs: https://documentation.appsonair.com/MobileQuickstart/CLI/ota-commands
#
# The CLI authenticates with a "CLI token" you copy from the AppsOnAir web app
# (app.appsonair.com → log in → copy the full CLI token). The current beta has
# no API-key/env auth, so CI pipes that token into `appsonair login` and uploads
# in *yaml mode* — workspace/app/paths come from a generated `.appsonair-cli.yaml`
# so nothing is interactive (path mode would prompt to pick the workspace/app).
#
# keytar is removed first so the CLI falls back to its file-based token store
# under ~/.config/appsonair (headless CI has no OS keychain / Secret Service).
#
# Required env: APPSONAIR_CLI_TOKEN, APPSONAIR_WORKSPACE_ID, APPSONAIR_APP_ID
# Optional env: APPSONAIR_APP_NAME (default Zoonze), APK_DIR (dist/apk), IPA_DIR (dist/ipa)
set -euo pipefail

: "${APPSONAIR_CLI_TOKEN:?APPSONAIR_CLI_TOKEN is required}"
: "${APPSONAIR_WORKSPACE_ID:?APPSONAIR_WORKSPACE_ID is required}"
: "${APPSONAIR_APP_ID:?APPSONAIR_APP_ID is required}"
APK_DIR="${APK_DIR:-dist/apk}"
IPA_DIR="${IPA_DIR:-dist/ipa}"
APP_NAME="${APPSONAIR_APP_NAME:-Zoonze}"

# Keep the CLI fully non-interactive in CI (skip its self-update check).
export APPSONAIR_DISABLE_UPDATE_CHECK=1
export CI=true

echo "Installing @appsonair/appsonair-cli…"
npm install -g @appsonair/appsonair-cli

# Force the file-based token store: drop keytar so the CLI's dynamic
# import("keytar") fails and it falls back to ~/.config/appsonair. Headless CI
# has no keychain/Secret Service, so a present-but-unusable keytar would break
# `login`. The CLI guards the import in try/catch, so removing it is safe.
groot="$(npm root -g)"
rm -rf "${groot}/keytar" \
       "${groot}/@appsonair/appsonair-cli/node_modules/keytar" 2>/dev/null || true

# yaml mode config — gives the CLI the workspace/app + build paths so the upload
# is non-interactive (no workspace/app picker). Re-generated each run.
cat > .appsonair-cli.yaml <<YAML
workspaceId: ${APPSONAIR_WORKSPACE_ID}
appId: ${APPSONAIR_APP_ID}
appName: ${APP_NAME}
ota:
  androidOutput: ${APK_DIR}
  iosOutput: ${IPA_DIR}
YAML
echo "Wrote .appsonair-cli.yaml (workspace ${APPSONAIR_WORKSPACE_ID}, app ${APPSONAIR_APP_ID})"

echo "Authenticating to AppsOnAir…"
printf '%s\n' "${APPSONAIR_CLI_TOKEN}" | appsonair login
appsonair whoami

apk="$(ls "${APK_DIR}"/*.apk 2>/dev/null | head -1 || true)"
ipa="$(ls "${IPA_DIR}"/*.ipa 2>/dev/null | head -1 || true)"
echo "APK: ${apk:-none}   IPA: ${ipa:-none}"

if [ -n "${apk}" ] && [ -n "${ipa}" ]; then
  appsonair-ota upload                 # both, from yaml
elif [ -n "${apk}" ]; then
  appsonair-ota upload --android
elif [ -n "${ipa}" ]; then
  appsonair-ota upload --ios
else
  echo "::warning::No APK/IPA found for AppsOnAir upload."
  exit 0
fi
echo "✅ AppsOnAir upload complete."
