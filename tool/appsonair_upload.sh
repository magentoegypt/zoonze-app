#!/usr/bin/env bash
# Upload a single build artifact (APK or IPA) to AppsOnAir for OTA distribution.
#
# AppsOnAir publishes no GitHub Action / fastlane plugin / CLI for build
# distribution, so we POST the file to their REST upload endpoint directly.
# Auth is header-based: x-api-key = API Key, x-app-key = App ID (both from
# AppsOnAir → App Settings). The exact upload URL (and, rarely, the multipart
# file field name) is shown in the AppsOnAir dashboard's API / CI-CD snippet —
# paste it into the APPSONAIR_UPLOAD_URL secret so we never hardcode a guess.
#
# Required env: APPSONAIR_UPLOAD_URL, APPSONAIR_API_KEY, APPSONAIR_APP_KEY
# Optional env: APPSONAIR_FILE_FIELD (multipart field name, default "file")
# Usage: tool/appsonair_upload.sh <path-to-apk-or-ipa>
set -euo pipefail

FILE="${1:?usage: appsonair_upload.sh <file>}"

if [ ! -f "$FILE" ]; then
  echo "::warning::AppsOnAir: file not found ($FILE) — skipping."
  exit 0
fi

: "${APPSONAIR_UPLOAD_URL:?APPSONAIR_UPLOAD_URL is required}"
: "${APPSONAIR_API_KEY:?APPSONAIR_API_KEY is required}"
: "${APPSONAIR_APP_KEY:?APPSONAIR_APP_KEY is required}"
FIELD="${APPSONAIR_FILE_FIELD:-file}"

echo "Uploading $(basename "$FILE") to AppsOnAir…"
resp_body="$(mktemp)"
http_code="$(
  curl -sS --max-time 600 -w '%{http_code}' -o "$resp_body" \
    -X POST "$APPSONAIR_UPLOAD_URL" \
    -H "x-api-key: ${APPSONAIR_API_KEY}" \
    -H "x-app-key: ${APPSONAIR_APP_KEY}" \
    -F "${FIELD}=@${FILE}" || echo "000"
)"

echo "AppsOnAir HTTP ${http_code}"
echo "--- response ---"; cat "$resp_body" 2>/dev/null || true; echo; echo "----------------"
rm -f "$resp_body"

case "$http_code" in
  2*) echo "✅ AppsOnAir upload OK: $(basename "$FILE")" ;;
  *)  echo "::error::AppsOnAir upload failed for $(basename "$FILE") (HTTP ${http_code}). Check APPSONAIR_UPLOAD_URL and the multipart field name (APPSONAIR_FILE_FIELD, default 'file')."
      exit 1 ;;
esac
