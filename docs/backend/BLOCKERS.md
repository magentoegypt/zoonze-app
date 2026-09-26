# Backend blockers — what the app is waiting on

Everything here needs a change on the **Magento / platform** side. The Flutter
app is built to consume each one the moment it lands and degrades gracefully
until then, so none of these crash the app — they leave a feature hidden,
a figure unexplained, or a flow unfinished.

Each item names the contract doc that specifies it. Those docs are the detail;
this file is the index, so the answer to "what is the backend holding up?" is
one page rather than seven.

**Last reviewed: 2026-09-26.** Items marked *verified today* were checked
against the app code and the live behaviour in that review. The rest are
carried from their contract docs — the requirement is as written there, but
whether the backend has since shipped it was **not** re-checked, so confirm
before acting on one.

| # | Blocker | Blocks | Source | Status |
|---|---------|--------|--------|--------|
| ~~1~~ | ~~`cod_fee` missing from `OrderTotal`~~ | — | [CL042-DEV43](https://app.clickup.com/t/14zb93nuzfu) | **Shipped 2026-09-26** · app wired |
| 2 | N-Genius session not returned through GraphQL | Card payments in the app; saved cards ride the same session | [ngenius-graphql-session.md](ngenius-graphql-session.md) | Root cause confirmed 2026-07-29 |
| 3 | Vault surface for `ngeniusonline` | Saved cards (CL042-DEV25) | [payment-contract.md](payment-contract.md) §④ | Specified, not confirmed live |
| 4 | No device-token endpoint / FCM sending | All push notifications | [notifications-contract.md](notifications-contract.md) | Not implemented |
| 5 | `ngeniusonline_applepay` absent from `available_payment_methods` | Apple Pay only — Samsung Pay now served | [payment-contract.md](payment-contract.md) | Narrowed 2026-09-26 · *verified today* |
| 6 | Free-shipping carrier offers no free method at threshold | Checkout charges shipping the cart promised free | [android-qa-backend-flags.md](android-qa-backend-flags.md) §1 | Open · config only |
| 7 | Assorted config/content gaps | Cosmetic + catalog | [android-qa-backend-flags.md](android-qa-backend-flags.md) §§2,3,4,6,8 | Open |
| 8 | Cart / wishlist not shared across web and app | Cross-platform continuity | *no contract doc* | Carried forward |
| 9 | Tamara absent from the checkout API entirely | Tamara as a payment method ([CL042-DEV42](https://app.clickup.com/t/14zb93nuzft)) | *no contract doc* | Open · *verified today* |

---

## 1. `cod_fee` on `OrderTotal` — ✅ RESOLVED

**Shipped 2026-09-26**, the same day it was asked for. A `Money`, always
present, `0` when it does not apply — the same shape as on `CartPrices` — and
on `guestOrder` too, so one selection covers customer and guest lookups.

Resolved against a real pre-module order, where the column is NULL: it returns
`0` rather than erroring, so historical orders need no special handling. They
do not reconcile retroactively, but nothing breaks.

**App side wired the same day:** `cod_fee` is selected on the order query,
carried on `CustomerOrder`, and the order detail screen shows a "Cash on
Delivery Fee" row between shipping and the total whenever the amount is above
zero. Orders that never carried the fee simply do not show the row.

## 2. N-Genius session not returned through GraphQL

Choosing "Visa & MasterCard" places the order but no card screen ever appears;
the same method works on the website. Root cause is documented and the fix is
backend-only.

**Blocks more than it looks:** saved cards (#3) ride the same session, so that
work cannot be verified until this is deployed.

**Meanwhile:** checkout shows "awaiting payment" and the order sits unpaid.

## 3. Vault surface for `ngeniusonline`

Read and delete are already live (`customerPaymentTokens`, `deletePaymentToken`,
`VaultTokenInput`). Outstanding: vault rows written for `ngeniusonline`, the
`is_active_payment_token_enabler` save flag, the `ngeniusonline_vault` method
code advertised only when a token exists, and `SetOrderPaymentMethodInput.public_hash`.

**Meanwhile:** the saved-card row stays hidden, and the save opt-in retries bare
rather than costing the shopper their order.

## 4. No device-token endpoint / FCM sending

The app has the FCM plumbing, a persisted inbox, a bell with an unread badge and
route mapping. Missing: a Firebase project, a Magento endpoint to register
device tokens, and Magento actually sending pushes on new customer, password
reset, and new/updated order.

**Meanwhile:** the notifications screen is permanently empty.

## 5. Apple Pay absent — Samsung Pay now served

Apple Pay and Samsung Pay are N-Genius **presentations**, not separate gateways:
same order, same session, only `method_code` differs
(`ngeniusonline_applepay` / `ngeniusonline_samsungpay`). They must arrive from
`available_payment_methods` like any other method — the app adds nothing and
only filters by a device-capability probe.

**Changed 2026-09-26:** `ngeniusonline_samsungpay` is now served on both store
views (checked on a live AE cart, `eg_en` and `eg_ar`). This entry was recorded
as "neither served" on 2026-08-20; only Apple Pay is still missing.

Since the app filters wallets by device capability, Samsung Pay should now
appear on capable Android hardware **without any app change** — that has not
been confirmed on a device, and is worth checking before assuming it works.

**Also external, not backend:** the Apple Pay processing certificate (CSR from
N-Genius), regenerating both committed provisioning profiles, and Samsung Pay
portal registration. See [decisions/payments.md](../decisions/payments.md) §5.

## 6. Free-shipping carrier offers no free method at threshold

The only item in the Android QA set that costs money rather than polish: the
cart promises free delivery at the configured threshold and checkout then
charges for it. Config-only fix.

## 7. Assorted config and content gaps

From the same doc, none of them blocking: footer social URLs for X and YouTube
(§2), the Shop-by-Category source not matching the website (§3), Arabic
push-notification text (§4), "Continue with Google" social login (§6), and the
PDP size selector, which is catalog modelling rather than code (§8).

## 8. Cart and wishlist not shared across web and app

The app side is correct (`customerCart`, `items_v2`). The fixes identified were
backend: the storefront `section_data_lifetime` TTL shortened for the cart, and
a store-agnostic `items_v2` resolver override for the wishlist.

**This one has no contract doc** — it comes from an earlier investigation. Worth
writing up properly before it is handed over, since the detail here is thinner
than every other entry.

## 9. Tamara absent from the checkout API entirely

[CL042-DEV42](https://app.clickup.com/t/14zb93nuzft) asks for Tamara. Checked
against the live store on 2026-09-26 — it is not reachable from the app by any
route:

| Check | Result |
| --- | --- |
| `available_payment_methods`, live AE cart, `eg_en` | Samsung Pay · Visa & MasterCard · Tabby · Cash On Delivery |
| same on `eg_ar`, cart at AED 2,490 | identical four — not a BNPL threshold |
| `PaymentGateway` enum on the live schema | `NGENIUS`, `TABBY` only |
| Any Tamara type in the schema | none |
| Any Tamara field on `StoreConfig` | none |

The app builds its checkout list strictly from `available_payment_methods` and
routes payment by the gateway the session reports, so there is nothing for app
code to bind to. Writing a gateway now would mean inventing the method code, the
enum value and the SDK contract, and finding out they were wrong when the
backend lands — so the app side is deliberately **not** started.

The absence of any schema type suggests the Magento module is not installed,
rather than installed but unexposed; admin is where to confirm that. Note the
ticket describes adding Tamara to the **website** — a method reaching the
website does not reach the app until its GraphQL surface exists, which is the
same gap as #2.

**Needed, mirroring Tabby:** the method in `available_payment_methods`, `TAMARA`
added to `PaymentGateway`, and `paymentSession` returning a Tamara session. Once
those exist the app work is a third `PaymentProvider` value, a resolver branch
and a gateway implementation — whose shape depends on whether Tamara ships a
Flutter package (like Tabby) or needs native code (like N-Genius). The
integration pack was emailed to the team and should settle that.

**Meanwhile:** no Tamara row appears, and checkout renders the four methods that
are served.

---

## Not a blocker, but unverified

The tracking timeline (CL042-DEV18) advances on `invoices` and `shipments` being
populated on `CustomerOrder`. The mapping is covered by tests against
constructed data, but **no real invoiced or shipped order has been checked**. If
`invoices` comes back empty on this store, "Order Confirmed" never lights up and
the QA failure recurs with a different cause. Confirm against a real order
before treating that ticket as closed.
