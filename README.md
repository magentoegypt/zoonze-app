# Zoonze App

Production-grade **Flutter** app — a bilingual (English/LTR + Arabic/RTL) headless
storefront client for the **ZoonZE Beauty** Magento Open Source 2.4.8-p5 backend
(`zoonze.com`, UAE, AED). Pure GraphQL client; no Magento PHP.

**Status (EN + AR/RTL throughout; `flutter analyze` clean, tests green):**
- **Phase 0 — Foundation** ✅ flavors, `AppConfig`, GraphQL link chain (dynamic
  `Store` header), dynamic store resolution, theme (Figma tokens +
  Inter/Cairo/Playfair), ARB + language switcher, secure storage + Hive, diagnostics.
- **Phase 1 — Catalog browse** ✅ app shell (drawer, bottom nav, footer),
  splash/welcome, home, PLP (filters/sort/pagination), PDP, search.
- **Phase 2 — Cart + Auth** ✅ guest cart, coupons, merge-on-login; sign in/up/reset, account.
- **Phase 3 — Checkout + payments** ⏸️ on hold pending the gateway-exposure answer (Open Q §2).
- **Phase 4 — Account/Wishlist/Reviews** ✅ wishlist, orders, addresses, edit profile, reviews.
- **Phase 5 — Push + release** 🔄 app-side push plumbing + deep links + release docs done;
  Firebase config, signing, iOS schemes, and store submission are owner/platform steps.

See `CLAUDE.md` (binding spec), `docs/PLAN.md` (phased roadmap + ETAs),
`docs/FIGMA_DESIGN.md` (UI source of truth), and `docs/decisions/`.

## Requirements
- Flutter **3.44.x** (stable) / Dart **3.12.x**

## Setup
```bash
flutter pub get
flutter gen-l10n        # generates lib/l10n/app_localizations*.dart
```

## Run (flavors via --dart-define-from-file)
```bash
flutter run -t lib/main_dev.dart     --dart-define-from-file=config/dev.json     --flavor dev
flutter run -t lib/main_staging.dart --dart-define-from-file=config/staging.json --flavor staging
flutter run -t lib/main_prod.dart    --dart-define-from-file=config/prod.json    --flavor prod
```
> Android product flavors are wired. iOS schemes per flavor must be added in
> Xcode (macOS) — see `docs/PLAN.md`.

## Verify
```bash
flutter analyze     # clean
flutter test        # unit + bidirectional widget tests
```

## Confirm store config / generate schema (run on a network that reaches zoonze.com)
```bash
bash tool/introspect.sh   # availableStores + per-view storeConfig + schema introspection
```
The build environment's egress policy blocks `zoonze.com`, so store codes are
**resolved dynamically at runtime** and the bootstrap values in `config/*.json`
are provisional until confirmed (see `docs/decisions/stores.md`).

## Project layout
```
lib/
  app/         MaterialApp.router, router, theme (Figma tokens)
  core/        config · graphql (link chain) · store (dynamic resolution)
               storage (secure/Hive/prefs) · error · widgets · assets
  features/    diagnostics (storeConfig health check)
  l10n/        app_en.arb · app_ar.arb
config/        dev|staging|prod.json   ·   tool/introspect.sh
```

## Conventions
Typed everything · repository boundary is sacred · errors are values
(localized `Failure`) · bidirectional by default · no fabricated data · token in
secure storage only · analyzer clean. (See `docs/decisions/architecture.md`.)
