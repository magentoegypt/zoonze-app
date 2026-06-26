# Decision: Phase 3 payments — native SDK integration

**Status:** Accepted (owner confirmed "a native SDK in phase 3").
**Resolves:** Open Question §2 (payment gateway exposure).
**Scope:** N-Genius (Network International, cards) + Tabby (BNPL, "Pay in 4").

The app integrates both gateways through **native mobile SDKs**, not a hand-rolled
WebView redirect. The Dart side is built and tested now; the native modules, SDK
dependencies, merchant credentials, and the one backend resolver below are the
on-platform steps (they need a device/Xcode build + secrets we don't hold here).

This decision is grounded in the live SDK/extension sources as of 2026 — see the
research notes at the bottom. **Introspect, don't assume**: pin the exact SDK
versions and the live `paymentSession` shape against the deployed store before release.

---

## 1. The architecture (in this repo)

A provider-agnostic seam so the screen never talks to an SDK directly:

```
checkout_screen._placeOrder()
  → placeOrder (Magento)                      → order_number
  → CheckoutController.loadPaymentSession()    → PaymentSession (backend resolver)
  → PaymentGatewayResolver.resolve(session)    → which gateway, or null
      ngenius + session_reference  → NativePaymentGateway  (MethodChannel → native SDK)
      redirect_url present         → RedirectPaymentGateway (in-app WebView; Tabby web_url / N-Genius HPP)
      not ready / nothing to open  → null → "awaiting payment" screen (no fake UI)
  → gateway.present() → PaymentOutcome {success, cancelled, rejected, failed, expired}
  → _handleOutcome(): reject/expire/cancel bounce back to method selection (§5)
```

Files: `domain/payment_session.dart` (`PaymentSession`, `PaymentOutcome`,
`PaymentSessionStatus`), `payments/payment_gateway.dart` (interface + resolver),
`payments/native_payment_gateway.dart`, `payments/redirect_payment_gateway.dart`,
`presentation/screens/payment_redirect_screen.dart`.

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

**Recommended contract — one custom GraphQL query** keyed by order number, serving both
gateways (runs *after* `placeOrder`, so it doesn't touch the cart mutation contract):

```graphql
type Query { paymentSession(order_number: String!): PaymentSessionOutput }

type PaymentSessionOutput {
  order_number: String!
  method_code: String!            # "ngenius_online" | "tabby_checkout" | ...
  status: PaymentSessionStatus!   # PENDING | READY | FAILED | REJECTED | EXPIRED
  session_reference: String       # N-Genius order ref · Tabby payment_id
  redirect_url: String            # Tabby web_url · N-Genius HPP (null for pure native)
  client_token: String            # short-lived access token, if any
  public_key: String              # Tabby publishable key for SDK init
  expires_at: String              # ISO-8601, optional
  additional_data: [KeyValue!]    # provider extras (e.g. Tabby available_products)
}
type KeyValue { key: String!  value: String }
enum PaymentSessionStatus { PENDING  READY  FAILED  REJECTED  EXPIRED }
```

Resolver effort is small: N-Genius wraps the existing gateway create-order call; Tabby
wraps `Model\SessionData::createSession()` (already returns `payment_id`). The app already
consumes this exact shape (`checkout_queries.paymentSession`) and **degrades to "awaiting
payment" if the field is absent**, so deploying it is non-breaking.

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
- Today the app presents Tabby's `web_url` through `RedirectPaymentGateway` (works once the
  backend returns it); swap to the official SDK for the promo widget (`TabbyProductPageSnippet`)
  and native callbacks. The publishable key comes from the session (`public_key`) — **no secret in the repo**.

### N-Genius — native SDKs + a thin platform channel
- Android `payment-sdk-android` (**v5.0.1**, JitPack: `com.github.network-international.payment-sdk-android:payment-sdk[-core]`), min API 21.
- iOS `NISdk` (**v6.0.1**, CocoaPods), iOS 13+.
- No official Flutter plugin — we own a thin bridge on `MethodChannel('com.zoonze.shop/payments')`.
  - Android: `PaymentClient(activity).launchCardPayment(CardPaymentRequest.Builder(gatewayUrl = payment-authorization href))`
    → `onActivityResult` → `CardPaymentData.getFromIntent(data)`; `executeThreeDS(...)` when needed.
  - iOS: `NISdk.sharedInstance.showCardPaymentViewWith(...)` with the full order response; conform to
    `CardPaymentDelegate.paymentDidComplete(with:)`.
  - Channel `invokeMethod('pay', { provider:'ngenius', orderNumber, gatewayUrl, sessionReference, clientToken, ... })`
    returns a status string mapped in `NativePaymentGateway._mapStatus`
    (`success|authorised|captured→success`, `cancelled→cancelled`, `rejected|declined→rejected`,
    `expired→expired`, else `failed`).
- Android needs the **`payment-authorization` href** (`redirect_url`/`session_reference`);
  iOS needs the **full order response** — surface the whole order-creation JSON in
  `session_reference`/`additional_data` so both platforms have what they need.

---

## 4. Sandbox identities (for integration tests)

- **N-Genius** (`api-gateway.sandbox.ngenius-payments.com`): 3DS-success Visa `4012001037141112`
  / `4111111111111111`; decline Visa `4663295942784758` (05). Mastercard success `5200000000000007`.
- **Tabby**: positive flow `otp.success@tabby.ai` + `+9715000000010` (UAE), OTP **8888**;
  background pre-scoring success `id.success@tabby.ai`. Verify the current reject/expiry
  identities against `docs.tabby.ai/testing-guidelines/testing-credentials` (README vs docs disagree).

---

## 5. Open items before go-live

1. **Add the `paymentSession` GraphQL resolver** (both gateways) — the hard blocker.
2. Add the native modules + SDK deps + merchant credentials (env/secret, never committed);
   add `tabby_flutter_inapp_sdk` if/when the Tabby promo widget + native callbacks are wanted.
3. Confirm Tabby visibility comes **only** from `cart { available_payment_methods }`; treat
   mid-flow **reject as a normal return**.
4. Verify exact SDK versions + the live `paymentSession`/Tabby return keys against the
   deployed store (`tool/introspect.sh` + a device build).

---

## Research provenance (2026)

- Tabby Flutter SDK: pub.dev `tabby_flutter_inapp_sdk` v2.0.0; `github.com/tabby-ai/tabby_flutter_inapp_sdk`; `docs.tabby.ai/api-reference/checkout/create-a-session`.
- Tabby Magento: `github.com/tabby-ai/m2-checkout` (`etc/webapi.xml`, `Model/SessionData.php`), `github.com/tabby-ai/m2-payments`.
- N-Genius SDKs: `github.com/network-international/payment-sdk-android` (v5.0.1), `github.com/network-international/payment-sdk-ios` (`NISdk` v6.0.1), `docs.ngenius-payments.com`.
- N-Genius Magento: `github.com/network-international/ngenius-magento-plugin` (HPP only).
- Magento GraphQL: `developer.adobe.com/commerce/webapi/graphql` (placeOrder/orderV2); community redirect-field pattern (MultiSafepay/Buckaroo/Mollie GraphQL modules, graphcommerce.org, scandipwa docs).
