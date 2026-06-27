# Decision — CI/CD (GitHub Actions)

Three workflows in `.github/workflows/`:

| Workflow | Trigger | Runner | Does |
|---|---|---|---|
| `ci.yml` | every push to `main` + PRs | ubuntu | `flutter analyze` + `flutter test` |
| `release-android.yml` | manual (pick flavor) | ubuntu | signed Play **.aab** → artifact |
| `release-ios.yml` | manual | **macOS** | build + upload to **TestFlight** (fastlane) |

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

**Without the secrets** the keystore step is skipped and the build falls back to
the **debug key** (a warning is logged) — the pipeline still produces an AAB so
you can validate the build, but it is **not** Play-uploadable until the `ANDROID_*`
secrets are set.

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

**One-time setup (no Mac needed):**
1. Create the empty private "match" repo (→ `MATCH_GIT_URL`).
2. Enrol in the Apple Developer Program; create the App ID `com.zoonze.shop` with
   **Push Notifications** enabled, and an **APNs key** (upload it to Firebase → Cloud Messaging).
3. Seed signing once: from any machine with Ruby, in `ios/`:
   `bundle install && bundle exec fastlane match appstore` (creates the cert +
   profile and pushes them, encrypted, to the match repo).
4. Put your **Team ID** in `ios/ExportOptions.plist` (`YOUR_TEAM_ID`).
5. Run **Release · iOS** from the Actions tab → it builds and pushes to TestFlight.

> First iOS run often needs a small tweak (Team ID, profile name, ipa path).
> Android + the CI job work as-is.

## Notes
- Pinned **Flutter 3.44.4** (matches the project's Dart `^3.12` constraint) — bump
  in all three workflows together if you change it.
- The iOS bundle id is `com.zoonze.shop` (pbxproj) and must match the committed
  `GoogleService-Info.plist` `BUNDLE_ID`. Use the **prod** plist for the store build;
  per-flavor iOS configs (.dev/.staging) need Xcode schemes added later.
