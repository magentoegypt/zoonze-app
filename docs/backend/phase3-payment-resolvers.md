# Backend hand-off — Phase 3 payment resolvers + native-SDK contract

**For:** Magento team (zoonze.com, Open Source 2.4.8-p5)
**Why:** The Flutter app integrates N-Genius (cards, native SDK) and Tabby (BNPL) for a
**headless** client. Neither extension exposes what a native client needs out of the box.
The app already consumes the contracts below and **degrades gracefully** (checkout shows
"awaiting payment"; the Tabby promo hides) until they ship — so deploying them is non-breaking.

**Scope = three items:** ① `paymentSession` resolver · ② `tabbyConfig` resolver · ③ the
native payment MethodChannel the Android/iOS modules implement. Full design context:
`docs/decisions/payments.md`.

---

## ① `paymentSession(order_number)` — GraphQL query

Returns the provider session reference for an order **after** `placeOrder`, keyed by order
number. One resolver serves both gateways. Store-scoped via the `Store` header.

```graphql
type Query {
  paymentSession(order_number: String!): PaymentSessionOutput
}

type PaymentSessionOutput {
  order_number: String!
  method_code: String!            # e.g. "ngenius_online" | "tabby_checkout" | "tabby_paylater"
  status: PaymentSessionStatus!   # PENDING | READY | FAILED | REJECTED | EXPIRED
  session_reference: String       # N-Genius: order reference (+ order-creation JSON for iOS); Tabby: payment_id
  redirect_url: String            # N-Genius: payment-authorization href / HPP; Tabby: web_url
  client_token: String            # short-lived access token the SDK needs, if any
  public_key: String              # Tabby publishable key for SDK init
  expires_at: String              # ISO-8601, optional
  additional_data: [KeyValue!]    # provider extras (e.g. N-Genius full order JSON, Tabby available_products)
}

type KeyValue { key: String!  value: String }
enum PaymentSessionStatus { PENDING  READY  FAILED  REJECTED  EXPIRED }
```

**Behaviour**
- **N-Genius** (`network-international/ngenius-magento-plugin` — no client API today): create
  the N-Genius order (existing `Gateway` create-order call) and return `status: READY` with
  `session_reference` = order reference, `redirect_url` = `_links.payment-authorization` href,
  and the **full order-creation JSON** in `additional_data` (iOS needs the whole object;
  Android needs the href). If the order can't be created → `FAILED`.
- **Tabby** (`tabby-ai/m2-checkout` — exposes this via REST already): wrap
  `Model\SessionData::createSession()`; return `status: READY` with `session_reference` =
  `payment_id`, `redirect_url` = the session `web_url`, `public_key` = publishable key, and
  Tabby `available_products` in `additional_data`. If Tabby pre-scoring rejects → `REJECTED`.
- `PENDING` = not ready yet (app shows "awaiting payment"). The app treats the session as
  presentable only when `status = READY` **and** (`redirect_url` or `session_reference`) is set.

**App routing (FYI):** N-Genius + a `session_reference` → native SDK; otherwise a
`redirect_url` → in-app WebView (Tabby web_url / N-Genius HPP).

> **Security:** the app re-queries order status server-side before showing success — never
> rely on the client return alone. Ensure order status is authoritative server-side
> (gateway webhook/capture), not flipped by this query.

---

## ② `tabbyConfig` — GraphQL query

Drives Tabby eligibility + the PDP/cart "Pay in 4 / Pay Later" promo **entirely from config**
(the app hardcodes nothing). One entry per Tabby product the merchant enables. Store-scoped.

```graphql
type Query { tabbyConfig: TabbyConfigOutput }

type TabbyConfigOutput {
  currency: String!                  # AED
  products: [TabbyProductConfig!]!
}

type TabbyProductConfig {
  type: TabbyProductType!            # PAY_IN_4 | PAY_LATER
  enabled: Boolean!
  installments: Int!                 # Pay in 4 → 4; Pay Later → 1
  min_order_total: Money             # inclusive lower bound (null = unbounded)
  max_order_total: Money             # inclusive upper bound (null = unbounded)
}

enum TabbyProductType { PAY_IN_4  PAY_LATER }
# Money is Magento's existing GraphQL type: { value: Float, currency: String }
```

**Source:** read enable flags + thresholds from the Tabby extension store config
(`tabby/m2-payments`). Emit one `products` entry per enabled product. Omit/disable products
the merchant hasn't turned on (the app shows only enabled, in-range products).
- Accepted `type` strings (app normalizes): `PAY_IN_4` / `PAY_IN_INSTALLMENTS` / `INSTALLMENTS`
  → Pay in 4; `PAY_LATER` / `PAYLATER` → Pay Later.

> Checkout availability of Tabby methods still comes from `cart { available_payment_methods }`
> (unchanged) — this resolver is for **eligibility + promo messaging** only.

---

## ③ Native payment MethodChannel (Android + iOS modules)

The app calls the native SDK over a Flutter `MethodChannel`. Backend/native scope: implement
the host side hosting **N-Genius `payment-sdk-android` (v5.0.1, JitPack)** and **iOS `NISdk`
(v6.0.1, CocoaPods)**. (Tabby is presented from Dart via its `web_url`; no channel needed.)

```
Channel : "com.zoonze.shop/payments"
Method  : "pay"
Args    : {
  provider         : "ngenius",
  orderNumber      : String,
  gatewayUrl       : String?,   // = paymentSession.redirect_url (payment-authorization href) — Android
  sessionReference : String?,   // = paymentSession.session_reference (+ order JSON via additional_data) — iOS
  clientToken      : String?,
  ...additionalData             // KeyValue pairs flattened (e.g. N-Genius full order JSON)
}
Return  : String status — one of:
  "success" | "authorised" | "authorized" | "captured"  → success
  "cancelled" | "canceled"                               → cancelled (user backed out)
  "rejected" | "declined"                                → declined
  "expired"                                              → expired
  (anything else / error)                                → failed
```

- **Android:** `PaymentClient(activity).launchCardPayment(CardPaymentRequest.Builder(gatewayUrl=...))`
  → `onActivityResult` → `CardPaymentData.getFromIntent(...)`; `executeThreeDS(...)` when prompted.
- **iOS:** `NISdk.sharedInstance.showCardPaymentViewWith(...)` with the full order response;
  conform to `CardPaymentDelegate.paymentDidComplete(with:)`.
- A `MissingPluginException` (module not installed) is handled by the app as `failed` — the
  order is already placed and shown as "awaiting payment", never a fake success.

---

## Definition of done
1. `paymentSession(order_number)` returns `READY` + the session ref/URL for both gateways
   (N-Genius order JSON in `additional_data`); `REJECTED` on Tabby pre-score decline; `FAILED`
   on create failure.
2. `tabbyConfig` returns one entry per enabled Tabby product with live thresholds in AED.
3. Native modules implement the `pay` channel and return the documented status strings.
4. Order status is authoritative server-side (webhook/capture); the client success re-query
   reflects it.
5. Sandbox: verify with the identities in `docs/decisions/payments.md` §4.

## References
- App contracts in code: `lib/features/checkout/data/checkout_queries.dart`
  (`paymentSession`, `tabbyConfig`), `lib/features/checkout/payments/`.
- Design + SDK versions + sandbox identities: `docs/decisions/payments.md`.
- Extensions: `github.com/tabby-ai/m2-checkout`, `github.com/network-international/ngenius-magento-plugin`.
