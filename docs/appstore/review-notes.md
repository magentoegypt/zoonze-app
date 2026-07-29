# App Review Information — Notes field

Paste-ready text for the **Notes** box in App Store Connect (4,000 char limit).
Fill in the two bracketed values before pasting.

Everything below is true of the shipped build and was checked against the code
or verified on device. Don't add claims a reviewer can't reproduce — a note
that promises something the app doesn't do is worse than no note.

---

```
ABOUT

Zoonze is the shopping app for zoonze.com, a beauty and fragrance retailer in
the United Arab Emirates. The app is a client of our existing storefront —
catalog, pricing, cart and orders all come from our live backend.

PHYSICAL GOODS ONLY — NOT IN-APP PURCHASE

Every item sold is a physical product (fragrance, skincare, makeup, hair care)
shipped to a street address in the UAE. Per Guideline 3.1.5(a), physical goods
and services are purchased outside of in-app purchase. The app sells no digital
content, subscriptions, or unlockable functionality.

SIGN-IN

A demo account is provided in the Sign-In Information fields above.

Signing in is not required to review most of the app: tap "Continue as guest"
on the welcome screen to browse the full catalog, search, and add items to a
cart. An account is needed only to place an order and to view order history.

HOW TO TEST A PURCHASE WITHOUT PAYING

At the payment step, choose Cash on Delivery. This places a real order in our
system with no card details and nothing charged. Please use the demo account so
we can identify and cancel the test order. Order confirmation, order history
and order tracking all work from this path.

LANGUAGES — ENGLISH AND ARABIC

Both are fully supported. Switch using the EN / AR toggle at the top of the
welcome screen, or later under Account > Settings > Language. Arabic renders
the entire interface right-to-left, and product and category names are served
in Arabic from our backend.

REGION

The store serves the UAE. Prices are shown in AED and delivery addresses are
limited to the seven emirates. The app itself is usable from any region — only
shipping is restricted — so everything is reviewable from outside the UAE.

PUSH NOTIFICATIONS

Used only for order status updates. iOS asks for permission on first launch;
the app is fully functional if permission is declined.

ACCOUNT DELETION

[FILL IN — see note below. Do not submit without this.]

CONTACT

[YOUR NAME / EMAIL] — happy to provide anything else needed for review.
```

---

## Blocker: account deletion is required and is not implemented

**Guideline 5.1.1(v):** an app that lets users create an account must let them
**delete** that account from within the app. Deactivation is not sufficient,
and pointing the user at a website or a support email is not sufficient.

Zoonze creates accounts (`createCustomerV2`, Sign Up screen), so the rule
applies. The app currently implements `deleteCustomerAddress` and
`deleteCustomerAvatar` but **nothing that deletes the account itself** — there
is no such action anywhere in the account or settings screens.

This is one of the most consistently enforced rejection reasons for a first
submission. It is worth fixing before submitting rather than absorbing a
rejection round-trip.

The backend already supports it: Magento's GraphQL schema exposes
`deleteCustomer: Boolean` (see `lib/core/graphql/schema.graphql:8328`), which
deletes the authenticated customer. What's missing is app-side: a
"Delete account" action in Settings, a confirmation step that makes the
consequence clear, the mutation call, and a local wipe (token, cart id, cached
customer state) with a return to the signed-out state.

Once that ships, the ACCOUNT DELETION section above should read roughly:

> Signed-in users can permanently delete their account and personal data from
> Account > Settings > Delete Account. The action asks for confirmation and
> then removes the customer record from our systems.
