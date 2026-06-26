# Decision — Release, flavors & deep links (Phase 5)

## Flavors
Three flavors (dev / staging / prod) via `--dart-define-from-file=config/<flavor>.json`
+ entrypoints `lib/main_{dev,staging,prod}.dart`. Android product flavors should
be added in `android/app/build.gradle` with distinct `applicationId` suffixes
(`com.zoonze.shop`, `.dev`, `.staging`); iOS schemes per flavor are added in Xcode
(macOS — not available in this environment).

## Deep links
- `go_router` is the deep-link target. Android `AndroidManifest.xml` declares:
  - custom scheme `zoonze://app/...`
  - https app links for `https://zoonze.com/...` (`android:autoVerify="true"`).
- **App-links verification** needs an `assetlinks.json` served at
  `https://zoonze.com/.well-known/assetlinks.json` with the app's signing SHA-256
  (owner + server task).
- iOS Universal Links need an `apple-app-site-association` file on the domain +
  the Associated Domains capability in Xcode.
- Payment return URLs (Phase 3) should reuse a deep-link-friendly return path so
  the N-Genius/Tabby WebView and push routing stay consistent.

## Signing (owner-provided — Open Q §9)
- **Android:** create a release keystore; put credentials in
  `android/key.properties` (git-ignored) and wire a `signingConfigs.release` in
  `android/app/build.gradle`. `flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json`.
- **iOS:** signing certificates + provisioning profiles in Xcode / App Store
  Connect.

## Permissions / config already wired
- `INTERNET` + `POST_NOTIFICATIONS` in `AndroidManifest.xml`; app label
  "ZoonZE Beauty".
- User-Agent header (`ZoonzeApp/<version>`) set on GraphQL requests — coordinate
  the CloudFront `/graphql` POST behavior + WAF allow-rule (Open Q §11).

## Store listing
- App icon / splash: replace the default launcher icons with the brand mark;
  bundle store screenshots (EN + AR) and copy. Track Play Console / App Store
  Connect ownership (Open Q §9).

## Pre-release QA checklist
- EN/LTR + AR/RTL sweep of every screen (the design specifies a full 52-frame
  mirror); confirm directional layout, Cairo for AR, Western numerals.
- `flutter analyze` clean, `flutter test` green, and the on-network smoke test
  (`tool/introspect.sh` + diagnostics screen).
