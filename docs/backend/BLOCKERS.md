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
| 9 | `TAMARA` missing from `PaymentGateway` — method is served but unpayable | Paying with Tamara ([CL042-DEV42](https://app.clickup.com/t/14zb93nuzft)) | *no contract doc* | **Live and urgent** 2026-09-28 |

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

## 9. Tamara is served but cannot be paid

**Changed 2026-09-28: Tamara went live.** `available_payment_methods` now
returns `tamara_pay_by_instalments` / "Tamara". Because checkout is built from
that list, the row appeared in the app **with no release** — including in
builds already with testers.

**But `PaymentGateway` still has only `NGENIUS` and `TABBY`.** The session
field is `gateway: PaymentGateway!` — non-nullable — so the resolver cannot
describe a Tamara session at all. It can only error, or name a gateway that is
not Tamara.

### What that broke, and what the app now does

`PaymentMethodOption.isRedirect` listed ngenius/tabby only, so Tamara read as a
**non-redirect** method — the class that finalises on `placeOrder` with no
payment step, like cash on delivery. A shopper selecting Tamara reached **order
success having paid nothing**. Fixed: Tamara is classified as the redirect
method it is, so it takes the session path.

With that fix the honest outcome is an order left **awaiting payment**: the
app asks for a session, cannot get a usable one, and says so rather than
claiming success. The shopper can retry from `CompletePaymentScreen` once the
backend lands.

### Config says two methods; only one is served

Admin has **both** `tamara_pay_now` and `tamara_pay_by_instalments` enabled
(Production, `https://api.tamara.co`, email whitelist off), and the live
credentials check returns:

| Product | Min | Max |
| --- | --- | --- |
| `PAY_BY_INSTALMENTS` | 1 | 100,000 AED |
| `PAY_NOW` | 1 | 7,500 AED |

But `available_payment_methods` returns **only instalments**, checked at AED 830
and AED 8,300. At 830 Pay Now is well inside its 7,500 ceiling and should be
offered, so its absence is not the cap — check Pay Now's own allowed countries,
min/max and customer-group settings, and that config cache was flushed. (At
8,300 its absence would be correct.)

The app is ready either way: both codes rank after Tabby and stay adjacent,
instalments first, and both are treated as redirect methods.

Also worth noting for the website/app gap: the **PDP widget is on** for the
storefront, from `cdn.tamara.co`. The app has no Tamara promo — the Tabby
equivalent is driven by a `tabbyConfig` query, and there is no Tamara
counterpart. Achieving parity would need one.

### Needed

`TAMARA` on the `PaymentGateway` enum, and `paymentSession` returning a Tamara
session (payment id / redirect URL) the way it does for Tabby. Then the app
needs a Tamara gateway implementation — Dart or native depending on what Tamara
ships, which the integration pack emailed to the team should settle.

> **Until then, consider disabling Tamara in Magento admin.** It is visible and
> selectable in the app right now, and every order placed with it will sit
> unpaid. Showing a method that cannot complete is worse than not offering it.

---

## Not a blocker, but unverified

The tracking timeline (CL042-DEV18) advances on `invoices` and `shipments` being
populated on `CustomerOrder`. The mapping is covered by tests against
constructed data, but **no real invoiced or shipped order has been checked**. If
`invoices` comes back empty on this store, "Order Confirmed" never lights up and
the QA failure recurs with a different cause. Confirm against a real order
before treating that ticket as closed.
