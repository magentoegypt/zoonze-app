# Zoonze App — Full Build Plan (Phases 0–5)

## Context

`magentoegypt/zoonze-app` is a **greenfield** repo (only `.git`, no files — even CLAUDE.md is uncommitted). The goal is a production-grade Flutter app: a headless storefront client for **Magento Open Source 2.4.8-p5** at `zoonze.com`, bilingual (EN/LTR + AR/RTL), **AED**, UAE market. CLAUDE.md is the binding spec; the app is a pure GraphQL client (no Magento PHP).

This is the **master plan across all phases with ETAs.** Execution is incremental per CLAUDE.md ("vertical slices; each phase ends shippable; small reviewable commits") — **this first PR delivers Phase 0**, and Phases 1–5 follow as their own slices/PRs. Say the word if you'd rather batch phases.

### Environment constraints (shape the plan)
- **`zoonze.com` is blocked** by the org egress policy (proxy 403 on CONNECT). I **cannot** run live `availableStores`/`storeConfig` from this session — CLAUDE.md's literal "first action" must run from a network that reaches the origin (scripted in `tool/introspect.sh`).
- **No Flutter/Dart SDK** preinstalled, but **`github.com` + `pub.dev` are reachable** → I install Flutter stable in-session, scaffold, run codegen, and gate on `flutter analyze` + `flutter test`. Full Android device build (Android SDK) and iOS schemes (Xcode/macOS) are the developer's local step.

### Decisions confirmed with owner
1. **Build approach:** install the SDK and verify (analyze + tests green).
2. **Store config:** **dynamic resolution** — bootstrap with a default store code, query `availableStores` at runtime, derive `locale → store_code`, default view, and currency from the response. No hardcoded codes as source of truth.
3. **Scope:** full Phase 0 foundation now; **all phases documented with ETAs.**

### Execution staging (owner-gated)
Per owner: do **NOT** start the app build yet. Two gated steps:
- **Step A — folder skeleton (now):** create the directory tree (`lib/...`, `assets/branding`, `assets/images`, `assets/fonts`, `config`, `docs/decisions`, `tool`, `test`, `integration_test`) with tracked `.gitkeep` placeholders, commit + push to `claude/happy-hopper-5s3x1z`, and open the PR. **No Flutter SDK install, no Dart code.** This gives you the exact folders to commit the **logo**, **test product image**, and **banner** into.
- **Step B — app build (on your confirmation):** only after you say go (and ideally after the images are committed) do I install the SDK, scaffold, write the Phase 0 code, run analyze/tests, and push. I **wait for explicit confirmation** between A and B.

---

## Plan ETA (my actual execution time, in hours)

This is **my estimate of the wall-clock hours I (the agent) spend actively executing** each phase — coding, running `pub get`/codegen/`analyze`/`test`, and fixing what breaks. Phase 0 includes the one-time Flutter SDK install (~30 min). These are **my hands-on-keyboard hours**; any time spent *waiting* on blockers (origin access, owner answers, backend/Xcode work) is separate and not counted here. "Solo?" flags what I cannot finish alone in this environment.

| Phase | Deliverable | My time (hours) | Can I finish solo? |
|---|---|---|---|
| **0** | Foundation (this PR) | **~3–4 h** (incl. SDK install) | ✅ Yes — except live introspection (origin blocked) → scripted for dev |
| **1** | Catalog browse | **~5–8 h** | ⚠️ Needs `schema.graphql` (blocked endpoint) + catalog-modeling answers (Open Q §4–§5) |
| **2** | Cart + Auth | **~4–6 h** | ⚠️ Needs schema; guest-checkout policy (Open Q §3) |
| **3** | Checkout + N-Genius + Tabby | **~7–10 h** | ❌ Blocked on gateway exposure (Open Q §2) + possible Magento backend work |
| **4** | Account + Wishlist + Reviews | **~4–6 h** | ⚠️ Needs schema |
| **5** | Push + polish + release | **~4–5 h** (code only) | ❌ Firebase / signing / WAF / macOS-Xcode are owner + platform tasks |
| | **Total app code** | **≈ 27–39 h** | Gated by endpoint access + Open Questions §11 |

What I can fully do **alone right now is Phase 0 — ~3–4 hours** to install the SDK, scaffold, write the code, get `flutter analyze` clean and `flutter test` green, commit, and open the PR. Everything past it is throttled by two things I can't supply myself: **(a)** a reachable `zoonze.com` so I can introspect `schema.graphql` and drive codegen, and **(b)** owner answers in Open Questions §11. Unblock those and I can run Phases 1–4 in the hours above; Phase 3 payments and Phase 5 release/signing still need human/platform involvement regardless. Estimates, not commitments.

---

## PHASE 0 — Foundation (this PR) · ETA 3–5 days

### Architecture
Feature-first, layered (CLAUDE.md §4): cross-cutting in `core/`; each feature owns `data/domain/presentation`; presentation → repository → GraphQL (boundary is sacred). Riverpod (`@riverpod` generator) for state + DI. `graphql_codegen` wired and ready, but the **two Phase-0 bootstrap ops** (`availableStores`, `storeConfig`) use hand-written documents + typed DTOs (the one scoped exception, since the live schema can't be introspected here yet; codegen takes over from Phase 1 once `schema.graphql` exists).

### Dynamic store resolution (owner's choice)
- `AppConfig` carries a **bootstrap** store code (`BOOTSTRAP_STORE_CODE`, provisional `uae-en`) used only for the first `availableStores` call, plus endpoint, default locale, fallback currency, user-agent, flavor.
- `StoreRepository.fetchAvailableStores()` → `availableStores(useCurrentGroup:false)` with the bootstrap `Store` header → `List<StoreView>` (code, name, locale, isDefault, base/display currency, base/secure/media URLs).
- `StoreController` (Riverpod `Notifier`): matches each `StoreView.locale` to app locales (`en`/`ar`), records the **default** store + currency, persists active locale (shared_preferences), caches the list (Hive) for next launch, exposes `activeStoreCode` for the header.
- **Atomic switch:** persist locale → `resetCache()` → rebuild `Directionality`/router via the locale provider.

### GraphQL link chain (`core/graphql/`)
`AuthLink` (bearer when present) → `StoreLink` (dynamic `Store` header + stable `User-Agent` + optional `Content-Currency`) → `ErrorLink` (401/`graphql-authorization` → clear token + logout; non-JSON/HTML WAF/CloudFront → friendly `Failure`; backoff-retry on transient 5xx/timeout) → terminating `HttpLink`. `graphqlClientProvider` builds the client with normalized cache + `resetCache()`.

### Execution steps
1. **Install + scaffold** Flutter stable (git clone from GitHub → PATH → precache), `flutter create` (org `com.zoonze.shop`, android+ios), restructure into the feature-first tree.
2. **Project config:** `pubspec.yaml` (deps via `flutter pub add`, versions captured), `analysis_options.yaml` (`flutter_lints`, clean), `.gitignore` (generated `*.g.dart`/`*.graphql.dart` ignored, bootstrap documented), `l10n.yaml`, `build.yaml`, `config/{dev,staging,prod}.json`.
3. **`core/config/`** `AppConfig` from `String.fromEnvironment`.
4. **`core/graphql/`** link chain + client provider + cache reset.
5. **`core/store/`** `StoreView` entity, `StoreRepository` (+ `availableStores.graphql` + DTO), `StoreController`.
6. **`core/storage/`** `SecureTokenStore` + `HiveBoxes` (store-list cache; future cart/wishlist/recently-viewed) + shared_preferences locale flag.
7. **`core/localization/` + `l10n/`** locale controller, `app_en.arb`/`app_ar.arb` (chrome strings), RTL/LTR utils.
8. **`app/`** `app.dart` (`MaterialApp.router` + theme + l10n + `Directionality`), `router.dart` (go_router; deep-link + auth-guard placeholders), `theme/` (Material 3 light/dark, **bundled Cairo/Tajawal** fetched from github.com/google/fonts + Latin fallback, directional-aware tokens/typography).
9. **`features/diagnostics/`** health-check screen: runs `storeConfig` for the active view, shows store_code/locale/currency/base URLs + a **language toggle** proving header-flip + cache-reset + RTL rebuild. The on-network live smoke test.
10. **Entrypoints** `main_{dev,staging,prod}.dart` → shared `bootstrap(flavor)`; Android product flavors (`...shop.dev/.staging`); iOS schemes documented (Xcode).
11. **Docs + tooling + spec:** commit **CLAUDE.md**; `docs/decisions/{stack,stores,architecture}.md`; `tool/introspect.sh` (`availableStores` + per-store `storeConfig` + full schema introspection → `schema.graphql`); `README.md`.
12. **Tests:** unit (`StoreController` mapping/default/currency; `ErrorLink` non-JSON→`Failure`; `AppConfig`); widget (health-check renders EN/LTR **and** AR/RTL, mocked repo, no network).

### Image assets (owner commits the actual files)
You'll commit three images yourself; I set up folders, pubspec declarations, a typed `AppImages` path constants file, and graceful `errorBuilder` fallbacks so the **build stays green now** and the images render automatically once added. Expected paths:
- **Logo** → `assets/branding/logo.png` (shown in the health-check/home header; later the app bar + splash).
- **Banner** → `assets/images/banner.png` (home/diagnostics banner).
- **Test product image** → `assets/images/test_product.png` (sample product tile for dev/preview).

Declared as **directory** assets (`assets/branding/`, `assets/images/`) with tracked `.gitkeep`s so missing-file builds don't break; `Image.asset(..., errorBuilder:)` degrades to a neutral placeholder until the files land (consistent with the no-fabricated-data rule). Filenames documented in `README.md`.

### Target structure (representative)
```
config/{dev,staging,prod}.json · l10n.yaml · build.yaml · analysis_options.yaml · README.md · CLAUDE.md
tool/introspect.sh · docs/decisions/*.md
assets/fonts/ · assets/branding/(logo.png) · assets/images/(banner.png, test_product.png)
lib/ main_{dev,staging,prod}.dart
  app/{app.dart, router.dart, theme/}
  core/{config, graphql, store, storage, localization, error, network, widgets, assets(app_images.dart)}/
  features/diagnostics/{data,presentation}/
  l10n/{app_en.arb, app_ar.arb}
test/ · integration_test/ (placeholder)
```

---

## PHASE 1 — Catalog browse, logged-out · ETA 8–12 days
**Deliver:** home (categories + featured), category PLP with **aggregations-driven** filters + sort + pagination, PDP (gallery, configurable swatches, per-variant price/stock), search. EN↔AR content switching verified. No cart yet.
**Ops:** `categoryList`/`categories`, `products(filter,search,sort,pageSize,currentPage)`, single product by `url_key`/`sku`, `configurable_options`+`variants`, `aggregations`. Start with native `products(search:)` (switch to `productSearch`/Live Search if Open Q §4 confirms it).
**Now codegen-first:** introspect `schema.graphql` (via `tool/introspect.sh` on dev network) → generate typed ops; build the catalog repository + Riverpod notifiers + screens. Widget tests for PDP/PLP in both directions.
**Risk:** depends on catalog modeling (Open Q §5 — real configurable attributes/swatches, proper categories). Render neutral states for missing swatches/stock (no fabricated data).

## PHASE 2 — Cart + Auth · ETA 6–9 days
**Deliver:** guest cart, cart screen (update/remove, coupons, totals), login/register/reset, **cart merge on login**, customer state across app.
**Ops:** `createEmptyCart`, `addProductsToCart` (unified mutation), `cart(cart_id)`, `updateCartItems`, `removeItemFromCart`, `applyCouponToCart`/`removeCouponFromCart`, `mergeCarts`; `generateCustomerToken`, `createCustomerV2`, `revokeCustomerToken`, `requestPasswordResetEmail`/`resetPassword`. Wire token into `AuthLink`; persist guest cart id (Hive); re-evaluate cart after a store switch.
**Risk:** merge edge cases + token-invalidation (treat 401/`graphql-authorization` as logout).

## PHASE 3 — Checkout + N-Genius + Tabby · ETA 10–18 days · **HIGH RISK**
**Deliver:** address (saved + new), shipping methods, payment selection driven **only** by `available_payment_methods`, `placeOrder`, **one shared redirect-WebView engine** parameterized per provider, return/**reject** handling + **server-side order re-query** before showing success, Tabby eligibility gating + "Pay in 4" promo on PDP/cart (if in scope).
**Ops:** `setShippingAddressesOnCart`, `setBillingAddressOnCart`, `available_shipping_methods`→`setShippingMethodsOnCart`, `available_payment_methods`→`setPaymentMethodOnCart`, `placeOrder`, order-status re-query.
**Must resolve first (Open Q §2):** for **N-Genius** and **Tabby** separately — is the redirect/session URL exposed via **GraphQL / REST / native SDK**? If GraphQL coverage is missing, a Magento resolver may be needed (backend work) — flag early; **do not stub fake card/installment UI.** Tabby: drive visibility from the API only; treat mid-flow **reject as a normal path**; use Tabby sandbox identities in integration tests.

## PHASE 4 — Account + Wishlist + Reviews · ETA 6–9 days
**Deliver:** profile, address book, order history + detail, wishlist, write/read reviews (**graceful empty states** — store has zero reviews), language switch in settings.
**Ops:** `customer`, `customer { orders }`/`customerOrders`, address CRUD, `updateCustomerV2`/`changeCustomerPassword`, `wishlists { items_v2 }` + add/remove, `product { reviews }`/`productReviewRatingsMetadata`/`createProductReview`. No fake stars when reviews absent.

## PHASE 5 — Push + polish + release · ETA 5–8 days
**Deliver:** FCM (order/promo topics) + local notifications, deep links (push + payment return URLs), performance pass, full EN/AR + RTL/LTR QA sweep, store-listing assets, release flavors + signing.
**Depends on (Open Q §9–§11):** Firebase project ownership, signing keys / Play Console + App Store Connect accounts, and the CloudFront `/graphql` POST behavior + WAF allow-rule for the app User-Agent.

---

## Cross-cutting rules (every phase)
Introspect don't assume · typed everything (codegen) · repository boundary sacred · errors are values → localized `Failure` · bidirectional by default (test EN/LTR **and** AR/RTL) · store switch atomic · no fabricated data · token in secure storage only / no PAN handling · tests for critical paths · small reviewable commits · analyzer clean.

## Verification
- **In-session (Phase 0 gate):** `flutter pub get` resolves; `dart run build_runner build` ok; `flutter analyze` clean; `flutter test` green (StoreController, ErrorLink, AppConfig, health-check EN/LTR + AR/RTL).
- **Developer on-network (origin blocked here):** `bash tool/introspect.sh` → confirm real `store_code`s/default/currency, update `docs/decisions/stores.md` + config, emit `schema.graphql`; then `flutter run --dart-define-from-file=config/dev.json --flavor dev` → health-check shows live storeConfig, language toggle flips header + RTL + refetches.
- Per phase thereafter: unit-test repositories (mock GraphQL client), widget-test key screens both directions, integration-test browse→cart→checkout (mock payment). Phase 3 uses Tabby sandbox scenarios.

## Flagged for owner
- iOS schemes/signing can't be generated here (no macOS/Xcode) — Android flavors wired now, iOS documented for local setup.
- Store codes/default/currency stay **unconfirmed** until `tool/introspect.sh` runs on-network; the app resolves them dynamically, so it's non-blocking for Phase 0.
- **Open Questions §11** (esp. payment exposure, guest checkout, Live Search, Tabby products/thresholds + promo scope, Firebase, WAF owner, app ids, numerals) must be answered before Phases 3–5 — they directly drive those ETAs.
