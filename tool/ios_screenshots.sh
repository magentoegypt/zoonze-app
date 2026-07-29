#!/usr/bin/env bash
# Capture App Store screenshots on an iOS Simulator. macOS only — runs in CI
# (.github/workflows/screenshots-ios.yml); there is no local Mac.
#
# Drives the app by deep link (zoonze://app/<route>) rather than by tapping
# coordinates, so it doesn't break when layout shifts. Simulator builds are
# debug-only on iOS (Flutter has no --profile/--release for the simulator);
# that's fine here because debugShowCheckedModeBanner is already false.
#
# NOTE: iOS deep linking needs FlutterDeepLinkingEnabled in Info.plist, which
# the shipped app does NOT set. The workflow patches it into the runner's
# checkout for this simulator build only — never committed, so the App Store
# IPA is unaffected. See docs/decisions/release.md.
set -euo pipefail

BUNDLE_ID="${BUNDLE_ID:-com.zoonze.shop}"
OUT_DIR="${OUT_DIR:-build/screenshots/ios}"
CONFIG_FILE="${CONFIG_FILE:-config/prod.json}"
LOCALE="${SHOT_LOCALE:-en}"

# App Store Connect's 6.5" slot accepts 1242x2688 or 1284x2778. Modern
# simulators render 1290x2796 (6.7"/6.9"), so normalise to 1284x2778 — the
# aspect ratios differ by <0.2%, which is imperceptible.
TARGET_W=1284
TARGET_H=2778

mkdir -p "$OUT_DIR"

# ---- pick an available simulator (preference order, newest first) ----
UDID=""
DEVICE_NAME=""
for name in "iPhone 16 Plus" "iPhone 16 Pro Max" "iPhone 16" \
            "iPhone 15 Plus" "iPhone 15 Pro Max" "iPhone 14 Plus"; do
  line="$(xcrun simctl list devices available | grep -F "    ${name} (" | head -n1 || true)"
  if [[ -n "$line" ]]; then
    UDID="$(printf '%s' "$line" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')"
    DEVICE_NAME="$name"
    break
  fi
done
if [[ -z "$UDID" ]]; then
  echo "::error::No suitable iPhone simulator found. Available devices:" >&2
  xcrun simctl list devices available >&2
  exit 1
fi
echo "Using simulator: ${DEVICE_NAME} (${UDID})"

cleanup() { xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

# Clean, Apple-style status bar (9:41, full bars, no carrier name).
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 \
  --wifiMode active --wifiBars 3 \
  --operatorName "" >/dev/null 2>&1 || true

# ---- build + install ----
# A fresh install has no persisted locale, so it falls back to DEFAULT_LOCALE.
# Override it (and the store code it bootstraps against) to capture the RTL set.
LOCALE_DEFINES=()
if [[ "$LOCALE" == "ar" ]]; then
  LOCALE_DEFINES+=(--dart-define=DEFAULT_LOCALE=ar --dart-define=BOOTSTRAP_STORE_CODE=eg_ar)
fi

echo "Building simulator app (${CONFIG_FILE}, locale=${LOCALE})…"
flutter build ios --simulator --debug \
  --dart-define-from-file="$CONFIG_FILE" "${LOCALE_DEFINES[@]+"${LOCALE_DEFINES[@]}"}"

APP_PATH="build/ios/iphonesimulator/Runner.app"
[[ -d "$APP_PATH" ]] || { echo "::error::$APP_PATH not found" >&2; exit 1; }
xcrun simctl install "$UDID" "$APP_PATH"

# ---- capture helper ----
shot() {
  local name="$1" route="${2:-}" settle="${3:-6}"
  if [[ -n "$route" ]]; then
    xcrun simctl openurl "$UDID" "zoonze://app${route}"
  fi
  sleep "$settle"
  local f="${OUT_DIR}/${LOCALE}-${name}.png"
  xcrun simctl io "$UDID" screenshot --type=png "$f"
  # sips -z takes HEIGHT then WIDTH.
  sips -z "$TARGET_H" "$TARGET_W" "$f" >/dev/null
  echo "  captured ${f}"
}

echo "Launching ${BUNDLE_ID}…"
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
# First launch goes splash -> bootstrap (availableStores/storeConfig) -> home.
# Give the live backend room; images stream in after first paint.
sleep 25

# Ordered as they should appear on the product page — the first three are what
# Apple shows on the install sheet.
shot "01-home"      ""                      8
shot "02-category"  "/category/Mw=="        12   # Fragrance (1796 products)
shot "03-product"   "/product/3616306115934" 12  # Gucci Bloom Parfum 100ml
shot "04-categories" "/categories"           8
shot "05-brands"    "/brands"               10
shot "06-wishlist"  "/wishlist"              6
shot "07-cart"      "/cart"                  6
shot "08-account"   "/account"               6

echo
echo "Done — ${OUT_DIR}:"
ls -la "$OUT_DIR"
