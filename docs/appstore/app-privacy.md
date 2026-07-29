# App Privacy questionnaire — answers (v1.0.0)

Answers for the **App Privacy** section in App Store Connect, derived from an
audit of the shipped code rather than assumption. Each "Yes" cites what in the
app collects it.

This is a legal declaration and Apple cross-checks it against app behaviour, so
where a call was a judgement rather than a fact it's marked **CONFIRM**.

**Nothing here is used for tracking.** The app bundles no advertising or
analytics SDK — the only Firebase packages are `firebase_core` and
`firebase_messaging` (push delivery). No data goes to a data broker and none is
joined with third-party data for ads. So every category below answers **No** to
"Used for Tracking", and the app needs no App Tracking Transparency prompt.

---

## Summary

| Apple category | Collected | Linked to user | Tracking |
|---|---|---|---|
| Contact Info — name, email, phone, physical address | Yes | Yes | No |
| Financial Info — payment info | **No** | — | — |
| Location | No | — | — |
| User Content — photos, other user content | Yes | Yes | No |
| Identifiers — user ID, device ID | Yes | Yes | No |
| Purchases — purchase history | Yes | Yes | No |
| Search History | **CONFIRM** | No | No |
| Browsing History | No | — | — |
| Usage Data | No | — | — |
| Diagnostics | No | — | — |
| Health, Sensitive Info, Contacts, Other | No | — | — |

---

## Category detail

### Contact Info — YES, linked, purpose: App Functionality

- **Name** — `createCustomerV2` at registration (firstname / lastname); also on
  every shipping and billing address.
- **Email Address** — registration and sign-in (`generateCustomerToken`).
- **Phone Number** — the `mobile_number` customer attribute, the WhatsApp OTP
  sign-in flow, and the phone on each saved address.
- **Physical Address** — the address book (`createCustomerAddress`), used for
  delivery.

Purpose is **App Functionality** only. Do not tick Product Personalization,
Analytics, or Developer Advertising — nothing in the app does those with it.

### Financial Info — NO

Worth stating plainly because it looks counter-intuitive for a shopping app:
**the app never receives payment details.** There is no payment SDK in the
build — the `zoonze/payments` MethodChannel declared in
`lib/features/checkout/payments/native_payment_gateway.dart` has **no native
implementation on either platform** (no handler in `AppDelegate.swift` /
`SceneDelegate.swift`, none in `MainActivity.kt`). Orders complete through cash
on delivery, which involves no card data. Nothing to declare.

> See the note at the bottom — this has a consequence beyond privacy.

### Location — NO

No location plugin is bundled (no `geolocator`, no `location`). The emirate on
an address is typed by the customer, which is Contact Info, not Location.

### User Content — YES, linked, purpose: App Functionality

- **Photos or Videos** — the profile avatar, chosen with `image_picker` and
  uploaded via `uploadCustomerAvatar`.
- **Other User Content** — product reviews written in the app
  (`createProductReview`).

### Identifiers — YES, linked, purpose: App Functionality

- **User ID** — the Magento customer identity behind the session token.
- **Device ID** — the FCM push token, sent to the backend by
  `registerDeviceToken` with the platform and app version so order
  notifications can reach this device. It is unregistered on sign-out.

### Purchases — YES, linked, purpose: App Functionality

Order history is stored server-side and shown under Orders, with tracking.

### Search History — CONFIRM

Search terms are sent to Magento to run the query. Magento's `search_query`
table retains terms and hit counts for its own search reporting, which likely
crosses Apple's threshold for "collected" — it outlives servicing the request.

It is **not linked to identity**: Magento records the term and a counter, not a
customer ID.

**Confirm with whoever administers the store**, then either declare Search
History as collected / not linked / App Functionality (safer), or declare it not
collected if search-term reporting is disabled. Over-declaring is not penalised;
under-declaring is.

### Browsing History — NO

Apple means content viewed *outside* the app. In-app category and product
browsing isn't this. Recently-viewed products are cached in local Hive storage
and never leave the device.

### Usage Data and Diagnostics — NO

No analytics SDK, no Crashlytics, no telemetry of taps, sessions or crashes.

---

## Privacy Policy URL

Required, and blocking — the section can't be published without it. It must be
a live page that actually describes the collection declared above. Reusing the
website policy is fine if it covers the mobile app.

`User Privacy Choices URL` is optional; leave blank unless a preference page
exists.

---

## Separate finding: payments do not work on iOS

Surfaced while auditing for Financial Info, and it matters beyond this form.

The `zoonze/payments` channel has no native implementation on either platform,
so N-Genius card payment and Tabby cannot complete a payment in the shipped
build. Only non-redirect methods — cash on delivery, and zero-subtotal orders —
can finish. This matches `CLAUDE.md`, which lists the native modules as
on-platform work still outstanding.

Consequences:

- The **review notes already say to test with cash on delivery**, so review is
  not blocked.
- The **listing copy already omits Tabby and card brands**, so nothing is
  claimed that a reviewer can't do.
- But a real customer choosing a card at checkout will not be able to pay. Worth
  confirming with the owner whether the store's `available_payment_methods` is
  currently limited to cash on delivery in production — if card is offered,
  customers are hitting a dead end.
