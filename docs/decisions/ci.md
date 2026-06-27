# Decision — CI/CD (GitHub Actions)

Workflows in `.github/workflows/`:

| Workflow | Trigger | Runner | Does |
|---|---|---|---|
| `ci.yml` | every push to `main` + PRs | ubuntu | `flutter analyze` + `flutter test` |
| `build-on-push.yml` | every push to `main` | ubuntu + macos-15 | **APK** (`apk-prod`) always; **iOS IPA** (`ipa-prod`) always — signed ad-hoc once Apple secrets exist, else an **unsigned** IPA (sideload/resign); then **auto-uploads both to AppsOnAir** when its secrets are set |
| `release-android.yml` | manual (pick flavor/format) | ubuntu | APK or Play **.aab** → artifact |
| `release-ios.yml` | manual | **macOS** | ad-hoc **.ipa** (Diawi) or TestFlight |
| `introspect.yml` | manual | ubuntu | live GraphQL introspection (store codes, schema, payment contract) |

> `build-on-push` makes every merge to `main` produce an installable APK (and an
> ad-hoc IPA once iOS signing is set up) — download from the run's Artifacts.
> The iOS job runs on **macOS every push** (uses macOS minutes): it builds the
> ad-hoc IPA when the Apple secrets are present, otherwise an unsigned compile
> check (stays green, no IPA).

Firebase config (`google-services.json` / `GoogleService-Info.plist`) is committed,
so the release workflows don't inject it. Only signing material comes from secrets.

## GitHub → Settings → Secrets and variables → Actions

### Android (release-android.yml)
| Secret | How to produce |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 zoonze-release.jks` (the keystore) |
| `ANDROID_STORE_PASSWORD` | keystore store password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | key alias (e.g. `zoonze`) |

The job decodes the keystore + writes `android/key.properties`; the Gradle config
already reads it. Output: `appbundle-<flavor>` artifact → upload to Play Console.

**Output format** (the `format` input): `apk` (default) builds a single
installable **`.apk`** — use this for **Diawi** / direct install / device
testing; `aab` builds the Play Store **app bundle** (NOT installable directly
or on Diawi); `both` builds each. Artifacts: `apk-<flavor>` / `appbundle-<flavor>`.

**Without the secrets** the keystore step is skipped and the build falls back to
the **debug key** (a warning is logged) — the build still completes (a debug-
signed APK installs fine for testing/Diawi), but it is **not** Play-uploadable
until the `ANDROID_*` secrets are set.

> **Core library desugaring** is enabled in `android/app/build.gradle.kts`
> (`isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs`), required by
> `flutter_local_notifications`. Without it the release build fails at
> `checkProdReleaseAarMetadata`.

### iOS (release-ios.yml)
Uses **fastlane** with an **App Store Connect API key** + **`match`** (so no Mac and
no manual certificate/CSR are needed).

| Secret | How to produce |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | same page → Issuer ID |
| `APP_STORE_CONNECT_KEY_CONTENT_BASE64` | `base64 -w0 AuthKey_XXXX.p8` |
| `MATCH_GIT_URL` | a **private** git repo URL that stores the signing cert/profile |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `base64 -w0 <<< "user:personal_access_token"` (read/write to the match repo) |
| `MATCH_PASSWORD` | passphrase you choose to encrypt the match repo |
| `APPLE_TEAM_ID` | your 10-char Apple Developer **Team ID** (Apple Developer → Membership). The workflow injects it into the `ExportOptions*.plist` so you don't edit them by hand. |

These same secrets drive the iOS build in **`build-on-push.yml`**: once they're set,
every push produces a **signed ad-hoc IPA** (`ipa-prod`) — no manual run needed.

**Distribution** (the `distribution` input):
- **`adhoc`** (default) → builds an ad-hoc **`.ipa`** artifact (`ipa-adhoc-prod`)
  for **Diawi** / direct device install. Lane `adhoc`, `ExportOptions-AdHoc.plist`.
- **`testflight`** → archives + uploads to **TestFlight**. Lane `beta`,
  `ExportOptions.plist`.

**One-time setup (no Mac needed):**
1. Create the empty private "match" repo (→ `MATCH_GIT_URL`).
2. Enrol in the Apple Developer Program; create the App ID `com.zoonze.shop` with
   **Push Notifications** enabled, and an **APNs key** (upload it to Firebase → Cloud Messaging).
3. **Register test-device UDIDs** (Apple Developer → Devices) — **required for
   ad-hoc/Diawi**: an ad-hoc IPA only installs on devices in its profile.
4. Seed signing once: from any machine with Ruby, in `ios/` —
   `bundle install` then `bundle exec fastlane match appstore` **and**
   `bundle exec fastlane match adhoc` (the latter bakes the registered devices
   into the ad-hoc profile; re-run it whenever you add a device).
5. Set the **`APPLE_TEAM_ID`** secret (the workflows substitute it into both
   `ExportOptions*.plist` at build time — no manual `YOUR_TEAM_ID` edit needed).
6. Run **Release · iOS** from the Actions tab:
   - `adhoc` → download the `ipa-adhoc-prod` artifact → upload the `.ipa` to **diawi.com**.
   - `testflight` → it builds and pushes to TestFlight.

> First iOS run often needs a small tweak (Team ID, profile name, ipa path).
> Android + the CI job work as-is.

> **Swift Package Manager + `flutter pub get`:** the iOS project uses SPM
> (`Runner.xcodeproj` references the Flutter-generated Swift package; there is
> **no Podfile**). Flutter 3.44 copies SPM plugins (firebase_*) into
> `build/ios/SourcePackages/` via rsync during `pub get`, which fails on a
> fresh checkout because that parent dir doesn't exist yet (`Failed to copy
> plugin … mkdir … No such file or directory`). Both macOS jobs run
> `mkdir -p build/ios/SourcePackages` before `flutter pub get` to work around
> it. Do **not** disable SPM (no Podfile to fall back to).

> **iOS toolchain:** `firebase_messaging` 16.4.1 → `firebase-ios-sdk` 12.15
> declares `swift-tools-version: 6.1`, which needs **Xcode 16.3+**. `macos-14`
> tops out around Xcode 16.2 (Swift 6.0) and fails SPM resolution
> (`incompatible tools version (6.1.0)`), so the iOS jobs run on **`macos-15`**
> and pin the newest stable Xcode via `maxim-lobanov/setup-xcode`. The same
> firebase packages also require an **iOS 15.0** minimum, so the Xcode project's
> `IPHONEOS_DEPLOYMENT_TARGET` is **15.0** (was 13.0).

> **iOS is non-blocking for now:** in `build-on-push.yml` the `ios` job is
> `continue-on-error: true` — the Android APK is the dependable artifact and an
> iOS failure won't fail the run while iOS is being brought online. Remove the
> flag once iOS builds reliably.

> **IPA without an Apple account (unsigned):** when the `APP_STORE_CONNECT_*` /
> `MATCH_*` secrets are absent, `build-on-push` still emits an **unsigned** IPA
> (`ipa-prod` → `Zoonze-unsigned.ipa`): it builds `Runner.app` with
> `--no-codesign` and zips it into the standard `Payload/Runner.app` IPA layout.
> An unsigned IPA does **not** install via Diawi or direct download as-is — it
> must be **resigned**. Practical install paths:
> - **AltStore** / **Sideloadly** — resign with your own (even free) Apple ID
>   and sideload onto your device. Good for quick personal testing.
> - **Diawi** — only works with a **signed ad-hoc** IPA, so add the Apple
>   secrets + run `fastlane match adhoc` (registers device UDIDs); then the same
>   job produces a signed `ipa-prod` that installs straight from Diawi.
> So: unsigned IPA = generated today, sideload to test. Signed ad-hoc IPA =
> needs the one-time Apple signing setup, then Diawi-installable.

### AppsOnAir distribution (build-on-push.yml → `appsonair` job)

On every push to `main`, after the APK and IPA build, the **`appsonair`** job
publishes **both** builds to [AppsOnAir](https://www.appsonair.com) for OTA
distribution (`tool/appsonair_upload.sh`). It's a no-op until these secrets are
set, so it never breaks the build.

| Secret | Where to find it |
|---|---|
| `APPSONAIR_API_KEY` | AppsOnAir → your app → **App Settings → API Key** (sent as the `x-api-key` header) |
| `APPSONAIR_APP_KEY` | AppsOnAir → your app → **App Settings → App ID** (sent as the `x-app-key` header) |
| `APPSONAIR_UPLOAD_URL` | the build-upload endpoint from AppsOnAir's **API / CI-CD** snippet in the dashboard (we don't hardcode it — paste the exact URL they show) |

Optional repo **variable** `APPSONAIR_FILE_FIELD` overrides the multipart file
field name (default `file`) if AppsOnAir's snippet uses a different one.

> AppsOnAir publishes **no** GitHub Action / fastlane plugin / CLI for build
> distribution (only CodePush for RN and the in-app AppSync SDK), so we upload
> via their REST API with `curl`. Auth is `x-api-key` (API Key) + `x-app-key`
> (App ID). **iOS caveat:** AppsOnAir installs over-the-air, which needs a
> **signed** IPA — so set the Apple signing secrets above (the `ios` job then
> emits a signed ad-hoc IPA). An unsigned IPA uploads but won't install.

## Notes
- Pinned **Flutter 3.44.4** (matches the project's Dart `^3.12` constraint) — bump
  in all three workflows together if you change it.
- The iOS bundle id is `com.zoonze.shop` (pbxproj) and must match the committed
  `GoogleService-Info.plist` `BUNDLE_ID`. Use the **prod** plist for the store build;
  per-flavor iOS configs (.dev/.staging) need Xcode schemes added later.
