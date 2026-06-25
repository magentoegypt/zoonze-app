# ZoonZE Beauty — Figma Design Handoff

High-fidelity mobile UI for the ZoonZE Beauty storefront (UAE · AED · EN/AR),
built to mirror the live `zoonze.com` mobile experience. This doc is the bridge
between the Figma source of truth and the Flutter implementation in this repo.

**Figma file:** https://www.figma.com/design/lxyvR0z3xERp8lw8IlPTlH/

The canvas holds **28 screens** organized into five labelled sections (Figma
*Sections*), stacked top-to-bottom in app-flow order:

| # | Section | Screens |
|---|---------|---------|
| 01 | Splash & Onboarding | Splash — Launch, Onboarding 1 (Authentic), Onboarding 2 (Curated), Onboarding 3 (Delivery), Splash — Welcome |
| 02 | Authentication | Sign In, Sign Up, Forgot Password |
| 03 | Home & Discovery | Home (UAE / EN), Categories, Search, Search Results, Filters (Sheet), PLP — Fragrance |
| 04 | Product · Wishlist · Cart | PDP (Coco Mademoiselle), Wishlist, Cart, Cart — Empty, Checkout, Order Success |
| 05 | Orders & Account | My Orders, Order Tracking, My Account, Saved Addresses, Add Address, Notifications, Help & FAQ, Edit Profile |

Sign-up collects **name, email, password only** — no mobile number and no SMS/OTP
verification step. Account details and preferences are edited on the **Edit Profile**
screen (reachable from My Account).

All device frames are **390 px** wide (iPhone logical width). Every screen exists
in two variants — **English / LTR** and a full **Arabic / RTL** mirror — laid out
in parallel section columns on the canvas (the AR sections are suffixed
`(AR / RTL)`), for **28 screens × 2 = 56 frames**.

### Arabic / RTL

The Arabic mirror of all 28 screens is generated from the LTR set:

- Text is set in **Cairo** (Regular / Medium / SemiBold / Bold), right-aligned.
- Layouts are mirrored — horizontal rows reversed, left/right padding swapped,
  absolutely-positioned elements mirrored, and back-arrows flipped.
- The **`ZOONZE` wordmark stays in English** (Playfair Display) in both languages.
  Brand names, product titles, prices, and order codes also remain Latin —
  standard for UAE bilingual storefronts.
- All UI chrome strings are translated to UAE Arabic; Western numerals are kept.

---

## Design tokens

Maintained in Figma as variable collections `Zoonze/Color` and `Zoonze/Scale`,
bound to fills so a single change cascades across every screen.

### Color

| Token | Hex | Use |
|-------|-----|-----|
| `brand/primary` | `#9E1B3F` | Burgundy — derived from the ZoonZE logo. Primary actions, prices, wordmark. |
| `brand/primary-pressed` | `#7E1632` | Pressed/active state. |
| `surface/tint` | `#FBF1F4` | Blush — section backgrounds, icon chips, empty-state circles. |
| `accent/sale` | `#EF4444` | Discount badges (e.g. `-24%`). |
| `accent/gold` | `#C9A24C` | `BESTSELLER` badge and review stars. |
| `ink/heading` | `#1F2937` | Headings / primary text. |
| `ink/muted` | `#6B7280` | Secondary text, struck-through prices. |
| `surface/dark` | `#1F2937` | Dark surfaces. |

### Type

- **Inter** — Regular / Medium / Semi Bold / Bold — all UI text, prices, labels.
- **Playfair Display Bold** — the `ZOONZE` wordmark, splash/onboarding headlines, and editorial titles.

### Components

A reusable library backs every screen: app bar, page title, buttons, inputs,
chips, list rows, section headers, tab bar, toggles, and the product card
(`product-card` → full-bleed `img` photo area, gold `BESTSELLER` / red discount
badges, stacked wishlist + share actions, stacked price with bold burgundy special
+ muted struck original).

---

## Brand assets → where they appear

The real brand assets committed to this repo are embedded directly into the
Figma file (raster fills) so the mockup uses live imagery, not placeholders.

| Repo asset | In the design | Notes |
|------------|---------------|-------|
| `assets/branding/favicon.ico` | The ornate **Z monogram** mark, placed immediately **before** the `ZOONZE` wordmark in the header lockup across the onboarding/auth screens and primary navigation screens (Welcome, Onboarding, Sign In, Home, Categories, PLP, PDP, Wishlist, Cart, Checkout, My Account). | Forms the icon + wordmark lockup. |
| `assets/branding/logo.png` | The full ZoonZE logo (Z-mark + wordmark), rendered **in white on the burgundy Launch splash**. | Elsewhere the wordmark is set in Playfair Display, paired with the favicon Z-mark. |
| `assets/images/banner.jpg` | **Home hero** (circular flatlay showcase), the **Welcome splash** visual, and the **Onboarding 1** hero. | Beauty-product flatlay. |
| `assets/images/test_product.jpg` | Product photography (full-bleed) on **every** product card, PLP grid, Search Results, Wishlist, the PDP main gallery + thumbnails, PDP related products, Cart line-items, Category tiles, and the Onboarding 2/3 heroes. | The four `test_product*` images are assigned round-robin across all product slots. |
| `assets/images/test_product_2.jpg` | ″ | |
| `assets/images/test_product_3.jpg` | ″ | |
| `assets/images/test_product_4.jpg` | ″ | |

Illustration spots that are **not** product slots — Forgot Password and the Empty
Cart empty-state — intentionally keep their icon/illustration, not a product photo.

---

## Screen specifics

### Splash & Onboarding
- **Launch** — full ZoonZE logo (Z-mark + wordmark) in white on burgundy, with the
  `BEAUTY & FRAGRANCE` tagline and a loading indicator.
- **Onboarding 1–3** — each slide has a rounded hero image, a 3-dot progress
  indicator (active dot is a burgundy pill), a Playfair headline, a muted subtitle,
  a **full-width** primary CTA (`Next` / `Get Started`), and an `Already have an
  account? Sign In` link.
- **Welcome** — favicon + wordmark lockup, flatlay visual, `Get Started`, sign-in
  and guest links.

### Product cards
- Image is **full-bleed** within the card.
- Top-left: `NEW` / `BESTSELLER` / discount badges. Top-right: a **wishlist (heart)**
  action with a **share** action stacked directly beneath it.
- Below the image: brand, title, and stacked price (bold burgundy special over a
  muted struck original).

### PDP
- **Full-bleed** main gallery image with a four-thumbnail strip beneath it.
- A **Description · Details · Reviews** tab bar.
- A full **Reviews** block: 4.6★ rating summary, per-star rating bars, verified
  review cards (avatar, name, stars, date), and a `Write a Review` action.

### Checkout (mirrors the live ZoonZE flow)
1. **Contact Information** — email.
2. **Shipping Address** — name, street, city, etc.
3. **Shipping Methods** — Standard Shipping (free) / Express Shipping (AED 10.00).
4. **Payment Method** — Check / Money order, Cash on Delivery, N‑Genius Online by
   Network, Pay later with Tabby.
5. **Order Summary** + **Complete Order**.

---

## Implementation notes

- Product imagery in the mockup is the `test_product*` set assigned round-robin;
  the Flutter app binds real catalogue media from Magento GraphQL at runtime.
- The hero, Welcome, and Onboarding visuals use the committed `banner.jpg` /
  product images; swap per campaign.
- Category tiles currently reuse product photography as representative imagery —
  replace with per-category art when available.
- Currency is **AED**; all copy shown is the EN/LTR variant.
