# Decision — CI/CD (GitHub Actions)

Workflows in `.github/workflows/`:

| Workflow | Trigger | Runner | Does |
|---|---|---|---|
| `ci.yml` | every push to `main` + PRs | ubuntu | `flutter analyze` + `flutter test` |
| `build-on-push.yml` | every push to `main` | ubuntu + macos-15 | **APK** (`apk-prod`) always; **iOS** always on macOS (non-blocking) — ad-hoc IPA (`ipa-adhoc-prod`) once Apple secrets exist, else an unsigned compile check |
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
5. Put your **Team ID** in `ios/ExportOptions.plist` **and**
   `ios/ExportOptions-AdHoc.plist` (`YOUR_TEAM_ID`).
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

## Notes
- Pinned **Flutter 3.44.4** (matches the project's Dart `^3.12` constraint) — bump
  in all three workflows together if you change it.
- The iOS bundle id is `com.zoonze.shop` (pbxproj) and must match the committed
  `GoogleService-Info.plist` `BUNDLE_ID`. Use the **prod** plist for the store build;
  per-flavor iOS configs (.dev/.staging) need Xcode schemes added later.
