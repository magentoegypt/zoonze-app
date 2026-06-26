# ZoonZE — Mobile Payment Contract (GraphQL + Native MethodChannel)

> Authoritative contract between the Flutter app and the Magento backend. The app
> already consumes the shapes below (`lib/features/checkout/`) and degrades
> gracefully until they ship: checkout shows "awaiting payment"; the Tabby promo
> hides. App-side design notes: `docs/decisions/payments.md`.

Backend module to create: **`MagentoEgypt_PaymentGraphQl`** (no GraphQL module exists yet).
Gateways in play (already installed): N-Genius (`networkinternational/ngenius`, method `ngeniusonline`)
and Tabby (`tabby/m2-checkout`, methods `tabby_installments`, `tabby_cc_installments`, `tabby_checkout`).

Two GraphQL queries + one Flutter `MethodChannel`:

1. `paymentSession(order_number)` — create / return a gateway session for an **already-placed** order.
2. `tabbyConfig` — Tabby eligibility + promo metadata (NOT checkout gating).
3. `zoonze/payments` MethodChannel — hand the session to the native N-Genius / Tabby SDK and map the result.

**Non-gateway methods need none of the above.** Methods with no off-site step — Magento's
**Zero Subtotal Checkout** (`free`, offered only when the grand total is 0), cash on delivery,
check/money-order — finalise on `placeOrder`. The app detects them as `!isRedirect`
(`PaymentMethodOption`; `free` also flagged `isFree`) and goes straight to order-success with **no**
`paymentSession` call. They still appear in checkout only if `Cart.available_payment_methods` returns
them; the app never injects `free`.

---

## ① `paymentSession(order_number)`

### SDL

> **Confirmed against the live schema (2026-06-26, CI introspection):** the
> deployed `paymentSession` takes **`(order_number, email, lastname)`** — there
> is **no `guest_token` argument**. The app was aligned to this: guests
> authorize with billing **email + lastname**; the order-token path was removed.
> (If the backend later adds `guest_token`, re-add it to the query + the
> `loadPaymentSession`/repository plumbing.)

```graphql
type Query {
    paymentSession(order_number: String!, email: String, lastname: String): PaymentSessionOutput
        @resolver(class: "MagentoEgypt\\PaymentGraphQl\\Model\\Resolver\\PaymentSession")
        @doc(description: "Create or return the gateway payment session for an already-placed order (keyed by increment id). Requires the customer/guest who owns the order.")
}

type PaymentSessionOutput {
    order_number: String!
    method_code: String!                 # ngeniusonline | tabby_installments | tabby_cc_installments | tabby_checkout
    gateway: PaymentGateway!
    status: PaymentSessionStatus!
    payment_id: String                   # Tabby payment.id | N-Genius order reference
    web_url: String                      # URL the native layer drives: N-Genius payment-authorization href, Tabby product web_url
    publishable_key: String              # Tabby public key (native Tabby SDK); null for N-Genius
    additional_data: [PaymentSessionData!]!   # raw gateway passthrough (full order JSON, hrefs, outlet ref, selected product…)
}

type PaymentSessionData {
    key: String!
    value: String
}

enum PaymentGateway {
    NGENIUS
    TABBY
}

enum PaymentSessionStatus {
    READY        # session usable now — app.isReady() == true → launch the native SDK
    PENDING      # session exists but not yet launchable (async gateway state) — app re-queries paymentSession
    REJECTED     # gateway refused to create a session (Tabby pre-score decline) — terminal, app must pick another method
    FAILED       # our-side / transient error creating the session — app may retry
}
```

### Authorization (guest vs logged-in)

A guest places the order without a customer bearer, so it must prove ownership of the order to
reach the gateway. The optional args carry the guest's credentials; the resolver accepts **either**
mechanism:

- **Logged-in customer:** `Authorization: Bearer <token>` is sent; the resolver matches the order
  to the customer and **ignores** the guest args (the app sends only `order_number`).
- **Guest — two interchangeable paths, the app sends both:**
  1. **`guest_token`** — Magento's order token (`placeOrder { orderV2 { token } }`, 2.4.7+). The
     resolver validates it the same way `guestOrderByToken` does.
  2. **`email` + `lastname`** — matched against the order's **billing address** (the classic
     Magento guest-order lookup).
  The resolver authorizes if **either** validates; if neither does → GraphQL authorization error.
  (`placeOrder` must therefore return `orderV2 { number token }` so the app can capture the token.)

### `isReady` contract

The app's `isReady()` is **exactly** `status == READY`. Only `READY` may launch the native SDK.

| status     | app behaviour                                                                 |
|------------|------------------------------------------------------------------------------|
| `READY`    | launch native SDK with `web_url` / `additional_data` (see ③).                |
| `PENDING`  | do **not** launch; re-call `paymentSession(order_number)` (back-off poll).   |
| `REJECTED` | terminal — show "Tabby unavailable for this order", fall back to another method. |
| `FAILED`   | retryable — show generic error + retry.                                       |

### Per-gateway resolver behaviour

**Resolution flow:** load order by `order_number` → assert ownership (logged-in: bearer matches the order's customer; guest: `guest_token` validates **or** `email` + `lastname` match the order's billing address) else GraphQL authorization error → read `order.payment.method` → dispatch to the gateway builder below → normalise to `PaymentSessionOutput`.

#### N-Genius (`ngeniusonline`)

The order endpoint is already hit at place-order time, producing the gateway order with a
`_links.payment.href` and `_embedded.payment[0].state = PENDING_AUTHORIZATION`
(see `NetworkInternational\NGenius\Gateway\Http\Client\PaymentTransaction::postProcess()` and the
`ngenius_networkinternational_sales_order` row: `reference`, `action`, `amount`, `state`, `status`).

The resolver returns that stored N-Genius order (re-fetching the order via the N-Genius order endpoint
if the stored row is stale):

- `gateway` = `NGENIUS`
- `payment_id` = N-Genius **order reference** (`reference`)
- `web_url` = the **payment-authorization href** (`_links.payment.href`, i.e. the `payment-authorization` link)
- `publishable_key` = `null`
- `status`:
  - `READY` when the auth href is present and `state == PENDING_AUTHORIZATION`
  - `PENDING` when the order exists but the auth href / state is not yet present
  - `FAILED` on order endpoint / token error
  - (N-Genius never returns `REJECTED` — pre-auth decline happens inside the SDK, surfaced via ③)
- `additional_data` keys:

  | key                          | value                                                              |
  |------------------------------|--------------------------------------------------------------------|
  | `order_reference`            | `reference`                                                        |
  | `payment_authorization_href` | `_links.payment.href`                                              |
  | `outlet_ref`                 | resolved outlet (`outlet_ref` / `outlet_ref_2` per currency)       |
  | `action`                     | `SALE` \| `AUTH` (`ngenius_payment_action`)                        |
  | `state`                      | `PENDING_AUTHORIZATION`                                            |
  | `order_response`             | **full order JSON, stringified** — iOS `NISdk` decodes this whole blob |

#### Tabby (`tabby_installments` / `tabby_cc_installments` / `tabby_checkout`)

Thin wrapper over the existing `Tabby\Checkout\Model\SessionData::createSession($quote)`, which returns:

```php
[[ "status" => $session->status,                       // "created" | "rejected"
   "payment_id" => $session->payment->id,
   "available_products" => $session->configuration->available_products ]]
```

Mapping:

- `gateway` = `TABBY`
- `payment_id` = `payment_id`
- `publishable_key` = `tabby/tabby_api/public_key` (store-scoped, decrypted)
- `web_url` = the selected product's web_url, picked from `available_products` by the order's method:
  - `tabby_installments` → `available_products.installments[0].web_url`
  - `tabby_checkout` → `available_products.pay_later[0].web_url`
  - `tabby_cc_installments` → `available_products.credit_card_installments[0].web_url`
- `status`:
  - `READY` when `status == "created"` **and** the selected product exists in `available_products`
  - `REJECTED` when `status == "rejected"` (Tabby **pre-score decline**) or the selected product is missing
  - `FAILED` on exception (`createSession` already swallows errors → `['status' => 'rejected']`; resolver may distinguish a thrown error as `FAILED`)
- `additional_data` keys: `merchant_code`, `selected_product` (`installments|pay_later|credit_card_installments`), `web_url`.

> The session must be built from the order's quote. Because `SessionData` reads the request body / checkout
> session, the resolver rebuilds the Tabby `payment` object from the placed order's items/totals rather than
> the live request (so it works headless from the app).

### `setOrderPaymentMethod` — retry / switch method on a placed order

After `placeOrder` the cart is consumed, so a failed/declined/cancelled payment can't be recovered by
re-running checkout. This mutation **changes the payment method on the already-placed order** and returns
a fresh session, powering the app's "Complete payment" screen (pay now with a different method, or pay
later). Same guest auth as `paymentSession` (order token / email + lastname / bearer).

```graphql
type Mutation {
    setOrderPaymentMethod(input: SetOrderPaymentMethodInput!): PaymentSessionOutput
        @resolver(class: "MagentoEgypt\\PaymentGraphQl\\Model\\Resolver\\SetOrderPaymentMethod")
        @doc(description: "Switch the payment method on an already-placed (pending-payment) order and return a fresh gateway session. Same ownership rules as paymentSession.")
}

input SetOrderPaymentMethodInput {
    order_number: String!
    method_code: String!     # the new method (must be valid for the order/store)
    email: String            # guest auth: billing email + lastname (no guest_token)
    lastname: String
}
```

- Assert ownership (same as `paymentSession`) → set the order's payment method to `method_code` (the order
  stays in pending-payment; no new order is created) → build + return the gateway session exactly like
  `paymentSession`. Same-method retry doesn't need this — the app just re-calls `paymentSession`.
- Until this mutation is deployed the app degrades to null → it shows "couldn't switch, try again / pay
  later" and the order remains awaiting payment (non-breaking).

---

## ② `tabbyConfig`

Eligibility + promo metadata only. **Checkout availability still flows from
`Cart.available_payment_methods`** (core `Magento\QuoteGraphQl` resolver) — this query never gates placing
an order; it drives Tabby promo widgets and pre-checkout eligibility hints.

### SDL

```graphql
type Query {
    tabbyConfig: TabbyConfigOutput
        @resolver(class: "MagentoEgypt\\PaymentGraphQl\\Model\\Resolver\\TabbyConfig")
        @doc(description: "Tabby eligibility + promo metadata for the current store/currency. Eligibility/promo only — actual checkout availability comes from Cart.available_payment_methods.")
}

type TabbyConfigOutput {
    enabled: Boolean!
    publishable_key: String              # tabby/tabby_api/public_key — native Tabby promo SDK
    merchant_code: String
    currency: String!                    # AED
    products: [TabbyProduct!]!           # one entry per ENABLED product
}

type TabbyProduct {
    type: TabbyProductType!
    method_code: String!                 # tabby_installments | tabby_cc_installments | tabby_checkout
    enabled: Boolean!
    min_amount: Float                    # AED threshold (inclusive)
    max_amount: Float                    # AED threshold (inclusive)
    promo_enabled: Boolean!              # product_promotions / cart_promotions
}

enum TabbyProductType {
    INSTALLMENTS
    PAY_LATER
    CREDIT_CARD_INSTALLMENTS
}
```

### Behaviour

- `enabled` = Tabby active for store (any product enabled, keys configured).
- `currency` = store base currency (`AED`).
- `products[]` = **one entry per enabled product**, thresholds in **AED**.
  - `min_amount` / `max_amount` come from the Tabby pre-score session limits when a cart exists, otherwise
    from store config (`payment/.../promo_min_total`, `promo_limit`) — `null` when Tabby imposes no bound.
  - `promo_enabled` = `product_promotions` (PDP) / `cart_promotions` (cart) config.

### Accepted type-string variants the app normalises → `TabbyProductType`

Tabby's API / config emits several spellings for the same product. The resolver normalises **case-insensitively**:

| `TabbyProductType`         | accepted source strings                                                       | method_code            |
|----------------------------|-------------------------------------------------------------------------------|------------------------|
| `INSTALLMENTS`             | `installments`, `installment`, `pay_in_4`, `split`                             | `tabby_installments`   |
| `PAY_LATER`                | `pay_later`, `paylater`, `pay-later`, `pay_in_14`, `pay later`, `tabby_checkout` | `tabby_checkout`     |
| `CREDIT_CARD_INSTALLMENTS` | `credit_card_installments`, `cc_installments`, `creditcard_installments`, `credit-card-installments` | `tabby_cc_installments` |

---

## ③ Native `MethodChannel` contract

Flutter ⇄ native bridge that launches the gateway SDK once `paymentSession` is `READY`.

- **Channel name:** `zoonze/payments`
- **Method:** `pay`
- **Returns:** `Map<String, dynamic>` with a normalised `status` string (table below). Native invokes the
  gateway SDK, waits for its delegate/callback, and resolves the `MethodChannel` result.

### `pay` argument map

```jsonc
{
  "gateway":      "ngenius" | "tabby",
  "methodCode":   "ngeniusonline" | "tabby_installments" | "tabby_cc_installments" | "tabby_checkout",
  "orderNumber":  "2000000123",
  "amount":       199.00,
  "currency":     "AED",

  // ---- N-Genius ----
  "orderResponse":             "<full order JSON string from additional_data.order_response>",  // iOS consumes
  "paymentAuthorizationHref":  "https://.../payment-authorization",                              // Android consumes
  "outletRef":                 "<outlet ref>",

  // ---- Tabby ----
  "webUrl":          "https://checkout.tabby.ai/...",   // both platforms (SDK webview)
  "publishableKey":  "pk_...",
  "paymentId":       "<tabby payment id>"
}
```

**Which field each platform consumes (N-Genius):**

| Platform | SDK entry point                                                                                     | Field consumed                       |
|----------|-----------------------------------------------------------------------------------------------------|--------------------------------------|
| Android  | `PaymentClient.launchCardPayment(cardPaymentRequest, requestCode)` — `CardPaymentRequest.builder().gatewayUrl(href).code(authCode).build()` derived from the `payment-authorization` href | **`paymentAuthorizationHref`**       |
| iOS      | `NISdk.sharedInstance.showCardPaymentViewWith(cardPaymentDelegate:, overParent:, for: order)` where `order: OrderResponse` is decoded from the full order JSON | **`orderResponse`** (full order JSON) |

> Both fields are always sent; each platform ignores the other's. Tabby uses `webUrl` + `publishableKey` +
> `paymentId` on both platforms.

### Native status strings → app result

Native normalises each SDK's callback to one canonical `status` string; the app maps as:

| app result  | canonical `status` strings                                  | N-Genius SDK source                                                                 | Tabby SDK source |
|-------------|-------------------------------------------------------------|-------------------------------------------------------------------------------------|------------------|
| **success** | `SUCCESS`, `AUTHORISED`, `CAPTURED`, `PURCHASED`            | iOS `.PaymentAuthorized` / `.PaymentCaptured`; Android `PAYMENT_AUTHORISED` / `PAYMENT_CAPTURED` | `authorized`     |
| **cancelled** | `CANCELLED`, `ABORTED`                                     | iOS `.PaymentAborted`; Android `PAYMENT_ABORTED` / user back                         | `closed`         |
| **declined** | `DECLINED`, `AUTH_FAILED`, `THREE_DS_FAILURE`              | iOS/Android post-auth decline                                                       | `rejected`       |
| **expired** | `EXPIRED`                                                   | —                                                                                   | `expired`        |
| **failed**  | `FAILED`, `ERROR`, *(anything unmapped)*                    | iOS `.PaymentFailed`; Android `PAYMENT_FAILED`; SDK init error                       | SDK/network error |

> N-Genius `.PaymentPostAuthReview` (iOS) / `PAYMENT_POST_AUTH_REVIEW` (Android) → treat as **success**
> (order placed, captured asynchronously). The app should still re-query order status afterwards.

### Result payload

```jsonc
{
  "status": "CAPTURED",          // canonical string from the table above
  "gateway": "ngenius",
  "orderNumber": "2000000123",
  "reference": "<gateway reference / tabby payment id>",
  "raw": "<optional raw SDK status / error message>"
}
```

After any non-`failed` return, the app re-queries the Magento order status (the gateway webhook/return
finalises the order server-side) before showing the success screen.

---

## App-side mapping (already implemented)

| Contract | App |
|---|---|
| `paymentSession` SDL | `CheckoutQueries.paymentSession` → `CheckoutRepository.fetchPaymentSession` → `PaymentSession` (`domain/payment_session.dart`) |
| guest auth args (`email` / `lastname`) | Billing `email`/`lastname` captured at the address step (`CheckoutState`). `CheckoutController.loadPaymentSession` sends them for guest orders, none for customers (bearer). No `guest_token` — the live schema doesn't define it |
| `isReady == READY` | `PaymentSession.isReady` (`status == ready`) |
| `PENDING` poll | `CheckoutController.loadPaymentSession` (back-off, 4 attempts) |
| post-order recovery | a failed/declined/cancelled payment routes to `CompletePaymentScreen` (pay now / switch method / pay later); driven by the shared `runPaymentSession` |
| `setOrderPaymentMethod` | `CheckoutRepository.setOrderPaymentMethod` — used by `CompletePaymentScreen` when the user picks a *different* method (same method re-calls `paymentSession`) |
| `tabbyConfig` SDL | `CheckoutQueries.tabbyConfig` → `fetchTabbyConfig` → `TabbyConfig` / `TabbyProduct` |
| type-string normalisation | `CheckoutRepository._tabbyType` |
| `zoonze/payments` channel | `NativePaymentGateway` (args + canonical status mapping) |
| status strings | `NativePaymentGateway._mapStatus` (POST_AUTH_REVIEW → success) |
