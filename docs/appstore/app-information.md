# App Information page — answers (v1.0.0)

Covers the **App Information** section in App Store Connect. Name and Subtitle
are already filled from `listing-en.md`; everything below is what's still blank
or needs a decision.

---

## Category

| Field | Value |
|---|---|
| Primary | **Shopping** |
| Secondary (optional) | **Lifestyle** |

Shopping is where a retail storefront belongs and is what beauty retailers
compete in. Avoid **Health & Fitness** as the secondary even though the app
sells skincare — it invites the medical questions in the age-rating
questionnaire and implies claims the app doesn't make.

---

## Content Rights

**Recommended answer: yes, it contains third-party content — and you have the
rights.**

The app displays manufacturer product photography, brand names and logos
(Gucci, Pixi and so on) served from the Magento catalog. That is third-party
content in Apple's sense, even though Zoonze is an authorised reseller
displaying goods it actually sells.

**This one is the owner's call, not a technical fact** — it asserts you hold
the necessary rights or permissions for that imagery. Confirm with whoever
manages the brand agreements before ticking it.

---

## Age Rating

Recommended answers. Expected result: **4+**, but see the blocker below.

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical or Treatment Information | None |
| Gambling, Contests, Loot Boxes | None |
| Unrestricted Web Access | **See below** |
| User-Generated Content | Yes — product reviews |

Notes on the two that aren't obvious:

- **Alcohol** — perfume is alcohol-based, but the question is about depicting or
  referencing alcohol *consumption*. None.
- **Medical or Treatment Information** — the app lists skincare products; it
  gives no diagnosis, dosage or treatment guidance. None. (This is also why
  Health & Fitness is the wrong secondary category.)
- **User-Generated Content** — customers can write product reviews
  (`createProductReview`). Reviews go through Magento's moderation queue rather
  than appearing instantly, which is what Apple cares about under Guideline
  1.2.

### Blocker: "Unrestricted Web Access" is currently **Yes**, which forces 17+

`WebViewScreen` (`lib/core/widgets/web_view_screen.dart`) sets
`JavaScriptMode.unrestricted` and installs a `NavigationDelegate` with **no
`onNavigationRequest`**. It opens a zoonze.com CMS page, but nothing stops a
link inside that page from navigating anywhere on the web. By Apple's
definition that is unrestricted web access.

That leaves two options, and only one of them is good:

1. **Answer Yes** → the app is rated **17+**. Bad for a beauty retailer, and it
   suppresses discovery.
2. **Restrict the WebView, then answer No** — add an `onNavigationRequest` that
   allows only `zoonze.com` (plus the payment gateway hosts) and sends anything
   else to the system browser via `url_launcher`, which the app already
   depends on.

Option 2 is a contained change and makes "No" an accurate declaration rather
than a convenient one. **Do not answer No while the WebView is unrestricted** —
Apple tests this, and a false declaration is a rejection plus a credibility
problem on re-review.

---

## App Encryption Documentation

**Nothing to do.** `ITSAppUsesNonExemptEncryption` is already `false` in
`ios/Runner/Info.plist:11`, which answers the export-compliance question
automatically at upload. The app uses only HTTPS/TLS, which is exempt. No
document upload is needed.

---

## Digital Services Act — trader status

The page currently reads *"This developer has identified itself as a
non-trader for this app."* **That is wrong for this app and needs fixing, one
way or the other.**

Zoonze sells physical goods for profit, which makes it a trader under the DSA.
Apple **removes non-trader apps from all EU storefronts**.

Two valid resolutions:

- **Declare trader status** and complete the verification (business address,
  phone, email — published on the product page), if the app should be visible
  in the EU. Reasonable for UAE expatriates and visitors who browse from EU
  accounts.
- **Leave it as non-trader and restrict availability** to the UAE/GCC under
  Pricing and Availability, accepting no EU presence.

Either is defensible; leaving it non-trader *and* available in the EU is not,
because the listing will simply disappear there.

---

## Fields already correct

| Field | Value |
|---|---|
| Name | Zoonze |
| Subtitle | Beauty, Fragrance & Skincare |
| Bundle ID | com.zoonze.shop |
| SKU | zoonze-shop-001 |
| Primary Language | English (U.S.) |
| License Agreement | Apple's standard EULA is fine — the app has no custom licence terms |

Localizable fields (Name, Subtitle) also need an **Arabic** version once that
localization is added — see `listing-ar.md`.
