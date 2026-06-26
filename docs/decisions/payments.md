# Decision: Phase 3 payments — native SDK integration

**Status:** Accepted (owner confirmed "a native SDK in phase 3").
**Resolves:** Open Question §2 (payment gateway exposure).
**Scope:** N-Genius (Network International, cards) + Tabby (BNPL: installments / pay later / card installments).

> **Authoritative contract:** `docs/backend/payment-contract.md` (module `MagentoEgypt_PaymentGraphQl`).
> This decision doc is the app-side rationale; where they differ, the contract wins. The Dart side
> already matches the contract field-for-field.

The app integrates both gateways through **native mobile SDKs**, not a hand-rolled
WebView redirect. The Dart side is built and tested now; the native modules, SDK
dependencies, merchant credentials, and the two backend resolvers are the
on-platform steps (they need a device/Xcode build + secrets we don't hold here).

---

## 1. The architecture (in this repo)

A provider-agnostic seam so the screen never talks to an SDK directly:

```
checkout_screen._placeOrder()
  → placeOrder (Magento)                        → order_number
  → CheckoutController.loadPaymentSession()      → PaymentSession (back-off poll while PENDING)
  → _drive(session) routes by status:
      READY     → PaymentGatewayResolver.resolve → NativePaymentGateway (channel zoonze/payments)
                    .present() → PaymentOutcome {success, cancelled, rejected, failed, expired}
                    → _handleOutcome(): reject/expire/cancel bounce back to method selection (§5)
      PENDING   → "awaiting payment" screen (not launchable)
      REJECTED  → terminal: reset payment + "choose another method"
      FAILED    → retryable: keep selection + retry
      (no session / module missing) → "awaiting payment" screen (no fake UI)
```

Both gateways are driven through the **single native channel** (`zoonze/payments`); the native
module hosts the N-Genius SDK and the Tabby SDK (Tabby's SDK renders its own hosted webview).
There is no Flutter-side WebView redirect engine — it was removed in favour of the native path.

Files: `domain/payment_session.dart` (`PaymentSession`, `PaymentProvider`, `PaymentOutcome`,
`PaymentSessionStatus`), `payments/payment_gateway.dart` (interface + resolver + `PaymentGatewayUnavailable`),
`payments/native_payment_gateway.dart`.

Server-side order-status re-query before showing success is still **mandatory** —
never trust the client return alone (CLAUDE.md §5).

---

## 2. The backend dependency (the real blocker)

Neither extension exposes the SDK session reference to a headless client out of the box:

- **N-Genius** `network-international/ngenius-magento-plugin` (HPP/redirect only): **no
  GraphQL, no client REST.** The order ref / `_links.payment-authorization` are produced
  server-side and consumed by a browser controller. A headless app **cannot** get them
  today → backend work required.
- **Tabby** `tabby-ai/m2-checkout`: exposes the session via **REST**, not GraphQL —
  `POST /V1/guest-carts/:cartId/tabby/session-data/` returns `{ status, payment_id,
  available_products }`. Reachable headlessly, but vendor-shaped.

**Final contract — `paymentSession(order_number)`** (full SDL + per-gateway resolver behaviour
in `docs/backend/payment-contract.md` §①):

```graphql
type PaymentSessionOutput {
  order_number: String!
  method_code: String!            # ngeniusonline | tabby_installments | tabby_cc_installments | tabby_checkout
  gateway: PaymentGateway!        # NGENIUS | TABBY
  status: PaymentSessionStatus!   # READY | PENDING | REJECTED | FAILED
  payment_id: String              # N-Genius order ref · Tabby payment.id
  web_url: String                 # N-Genius payment-authorization href · Tabby product web_url
  publishable_key: String         # Tabby public key (native SDK); null for N-Genius
  additional_data: [PaymentSessionData!]!   # full order JSON, hrefs, outlet ref, selected product…
}
enum PaymentGateway { NGENIUS  TABBY }
enum PaymentSessionStatus { READY  PENDING  REJECTED  FAILED }
```

The query is `paymentSession(order_number: String!, email: String, lastname: String)`. `isReady`
is **exactly** `status == READY`. N-Genius wraps the existing gateway create-order call (returns the
`_links.payment-authorization` href + full order JSON in `additional_data.order_response`); Tabby
wraps `Model\SessionData::createSession()` (returns `payment_id` + `web_url`). The app already
consumes this shape (`checkout_queries.paymentSession`) and **degrades to "awaiting payment" if the
field is absent**, so deploying it is non-breaking.

**Guest orders reach the gateway** via the optional `guest_token` / `email` / `lastname` args: a
logged-in customer is authorized by the bearer (app sends only `order_number`); a guest is
authorized by **either** Magento's order token (`placeOrder.orderV2.token`, captured as
`PlaceOrderResult.guestToken`) **or** the billing `email` + `lastname` it entered at checkout. The
app captures both at place-order / the address step (`CheckoutState`) and `loadPaymentSession` sends
all three for guest orders only — the resolver uses whichever validates.

### Tabby config — three products, backend-driven enable + thresholds + promo

Tabby carries three products — **INSTALLMENTS** ("Pay in 4"), **PAY_LATER**, and
**CREDIT_CARD_INSTALLMENTS** — each enabled independently with its own AED thresholds and a
separate `promo_enabled` toggle. **Nothing is hardcoded in the app.** Full SDL + type-string
normalisation in `docs/backend/payment-contract.md` §②:

```graphql
type TabbyConfigOutput {
  enabled: Boolean!
  publishable_key: String
  merchant_code: String
  currency: String!                  # AED
  products: [TabbyProduct!]!         # one entry per ENABLED product
}
type TabbyProduct {
  type: TabbyProductType!            # INSTALLMENTS | PAY_LATER | CREDIT_CARD_INSTALLMENTS
  method_code: String!               # tabby_installments | tabby_cc_installments | tabby_checkout
  enabled: Boolean!
  min_amount: Float                  # inclusive AED bound (null = unbounded)
  max_amount: Float                  # inclusive AED bound (null = unbounded)
  promo_enabled: Boolean!            # product_promotions (PDP) / cart_promotions (cart)
}
```

App side (`domain/tabby_config.dart`, `payments/tabby_promo.dart`):
- `tabbyConfigProvider` (FutureProvider) reads `fetchTabbyConfig()`; null when the resolver
  isn't deployed or Tabby is unconfigured → **promo hidden** (no fabricated eligibility).
- `TabbyProduct.isPromoEligible(price, currency)` gates a promo on enable **+ promo_enabled** +
  currency + min/max; `TabbyConfig.promoFor(price)` returns the promo-eligible products.
- `TabbyPromo(price:)` renders **one line per promo-eligible product** on the **PDP** (under the
  price) and **cart** (under the grand total): "or 4 interest-free payments of AED X" for
  installments (count 4 by Tabby definition), "or pay later, interest-free", "or pay by card in
  instalments". Hidden when none qualify.
- Checkout labels reflect the product too: `PaymentMethodOption.tabbyProduct` (from the method
  code) drives the payment-card subtitle. The method list itself still comes only from
  `cart { available_payment_methods }`, so the backend controls which products appear at checkout.
- The official `tabby_flutter_inapp_sdk` ships `TabbyProductPageSnippet` (a richer, dynamic promo)
  — swap `TabbyPromo` for it once the SDK + publishable key are wired; the config gate stays the
  source of truth either way.

---

## 3. The SDKs (pin versions at integration time)

### Tabby — official Flutter package
- `tabby_flutter_inapp_sdk` (pub.dev, publisher **tabby.ai**, **v2.0.0**, MIT). Renders
  Tabby's hosted session in an embedded WebView with structured callbacks.
- Flow: `await TabbySDK().setup(withApiKey: <publishable key>)` →
  `createSession(TabbyCheckoutPayload(merchantCode:'ae', lang:Lang.en|ar, payment: Payment(amount, Currency.aed, Buyer, order)))`
  → check `session.status` (`created`/`rejected`) → `TabbyWebView.showWebView(context:, webUrl: session.availableProducts.installments.webUrl, onResult:)`.
- `WebViewResult` → our `PaymentOutcome`: `authorized→success`, `rejected→rejected`,
  `expired→expired`, `close→cancelled`. Pre-`created` rejection bounces back **before** the WebView.
- The native module hosts this SDK and is invoked via the `zoonze/payments` channel with the
  Tabby `web_url` + `publishable_key` + `payment_id` from the session — **no secret in the repo**.

### N-Genius — native SDKs + a thin platform channel
- Android `payment-sdk-android` (**v5.0.1**, JitPack: `com.github.network-international.payment-sdk-android:payment-sdk[-core]`), min API 21.
- iOS `NISdk` (**v6.0.1**, CocoaPods), iOS 13+.
- No official Flutter plugin — we own a thin bridge on `MethodChannel('zoonze/payments')`,
  method `pay` (full arg map + result in `docs/backend/payment-contract.md` §③).
  - Android: `PaymentClient(activity).launchCardPayment(CardPaymentRequest.Builder(gatewayUrl = payment-authorization href))`
    → `onActivityResult` → `CardPaymentData.getFromIntent(data)`; `executeThreeDS(...)` when needed.
  - iOS: `NISdk.sharedInstance.showCardPaymentViewWith(...)` with the full order response; conform to
    `CardPaymentDelegate.paymentDidComplete(with:)`.
  - `pay` returns a **result map**; `NativePaymentGateway._mapStatus` maps the canonical `status`
    (`SUCCESS|AUTHORISED|CAPTURED|PURCHASED|POST_AUTH_REVIEW→success`, `CANCELLED|ABORTED|CLOSED→cancelled`,
    `DECLINED|AUTH_FAILED|THREE_DS_FAILURE|REJECTED→rejected`, `EXPIRED→expired`, else `failed`).
- Android consumes `paymentAuthorizationHref` (= `web_url`); iOS consumes `orderResponse`
  (the full order JSON in `additional_data.order_response`).

---

## 4. Sandbox identities (for integration tests)

- **N-Genius** (`api-gateway.sandbox.ngenius-payments.com`): 3DS-success Visa `4012001037141112`
  / `4111111111111111`; decline Visa `4663295942784758` (05). Mastercard success `5200000000000007`.
- **Tabby**: positive flow `otp.success@tabby.ai` + `+9715000000010` (UAE), OTP **8888**;
  background pre-scoring success `id.success@tabby.ai`. Verify the current reject/expiry
  identities against `docs.tabby.ai/testing-guidelines/testing-credentials` (README vs docs disagree).

---

## 5. Open items before go-live

1. **Build module `MagentoEgypt_PaymentGraphQl`** with the `paymentSession` + `tabbyConfig`
   resolvers (`docs/backend/payment-contract.md` §①–②) — the hard blocker.
2. Implement the native `zoonze/payments` modules (Android `payment-sdk-android`, iOS `NISdk`,
   Tabby SDK) per the channel contract (§③); add SDK deps + merchant credentials (env/secret,
   never committed). Optionally add `tabby_flutter_inapp_sdk` for the richer promo widget.
3. Confirm Tabby checkout visibility comes **only** from `cart { available_payment_methods }`;
   treat mid-flow **reject as a normal return**.
4. Verify exact SDK versions + the live `paymentSession`/`tabbyConfig` shapes against the
   deployed store (`tool/introspect.sh` + a device build).

---

## Research provenance (2026)

- Tabby Flutter SDK: pub.dev `tabby_flutter_inapp_sdk` v2.0.0; `github.com/tabby-ai/tabby_flutter_inapp_sdk`; `docs.tabby.ai/api-reference/checkout/create-a-session`.
- Tabby Magento: `github.com/tabby-ai/m2-checkout` (`etc/webapi.xml`, `Model/SessionData.php`), `github.com/tabby-ai/m2-payments`.
- N-Genius SDKs: `github.com/network-international/payment-sdk-android` (v5.0.1), `github.com/network-international/payment-sdk-ios` (`NISdk` v6.0.1), `docs.ngenius-payments.com`.
- N-Genius Magento: `github.com/network-international/ngenius-magento-plugin` (HPP only).
- Magento GraphQL: `developer.adobe.com/commerce/webapi/graphql` (placeOrder/orderV2); community redirect-field pattern (MultiSafepay/Buckaroo/Mollie GraphQL modules, graphcommerce.org, scandipwa docs).
