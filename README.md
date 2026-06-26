# Zoonze App

Production-grade **Flutter** app — a bilingual (English/LTR + Arabic/RTL) headless
storefront client for the **ZoonZE Beauty** Magento Open Source 2.4.8-p5 backend
(`zoonze.com`, UAE, AED). Pure GraphQL client; no Magento PHP.

**Status:** Phase 0 (foundation) complete — flavors, `AppConfig`, GraphQL link
chain with a dynamic `Store` header, dynamic store resolution, theming (Figma
tokens + Inter/Cairo/Playfair), bilingual ARB + RTL/LTR + language switcher,
secure storage + Hive, and a live `storeConfig` health-check screen.

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
