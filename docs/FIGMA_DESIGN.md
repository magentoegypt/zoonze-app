# ZoonZE Beauty — Figma Design Handoff

High-fidelity mobile UI for the ZoonZE Beauty storefront (UAE · AED · EN/AR),
built to mirror the live `zoonze.com` mobile experience. This doc is the bridge
between the Figma source of truth and the Flutter implementation in this repo.

**Figma file:** https://www.figma.com/design/lxyvR0z3xERp8lw8IlPTlH/

The canvas is organized into four labelled sections (Figma *Sections*):

| # | Section | Screens |
|---|---------|---------|
| 01 | Onboarding & Auth | Splash — Launch, Splash — Welcome, Sign In, Sign Up, OTP Verification, Forgot Password |
| 02 | Home & Discovery | Home (UAE / EN), Categories, Search, Search Results |
| 03 | Product · Wishlist · Cart | PLP (Fragrance), PDP (Coco Mademoiselle), Wishlist, Cart, Cart — Empty, Checkout, Order Success, Filters (Sheet) |
| 04 | Orders & Account | My Account, My Orders, Order Tracking, Saved Addresses, Add Address, Payment Methods, Notifications, Help & FAQ |

All device frames are **390 px** wide (iPhone logical width), LTR/EN. The Arabic
RTL mirror is produced at implementation time from the same components.

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
| `accent/gold` | `#C9A24C` | `BESTSELLER` badge. |
| `ink/heading` | `#1F2937` | Headings / primary text. |
| `ink/muted` | `#6B7280` | Secondary text, struck-through prices. |
| `surface/dark` | `#1F2937` | Dark surfaces. |

### Type

- **Inter** — Regular / Medium / Semi Bold / Bold — all UI text, prices, labels.
- **Playfair Display Bold** — the `ZOONZE` wordmark and editorial headlines.

### Components

A reusable library backs every screen: app bar, page title, buttons, inputs,
chips, list rows, section headers, tab bar, and the product card
(`product-card` → `img` photo area, gold `BESTSELLER` / red discount badges,
wishlist heart, stacked price with bold burgundy special + muted struck original).

---

## Brand assets → where they appear

The real brand assets committed to this repo are embedded directly into the
Figma file (raster fills) so the mockup uses live imagery, not placeholders.

| Repo asset | In the design | Notes |
|------------|---------------|-------|
| `assets/branding/favicon.ico` | The ornate **Z monogram** mark, placed immediately **before** the `ZOONZE` wordmark on all 11 logo-bearing screens (both splash screens, Sign In, Home, Categories, PLP, PDP, Wishlist, Cart, Checkout, My Account). | Forms the icon + wordmark lockup. |
| `assets/branding/logo.png` | Full `ZOONZE` wordmark lockup. | Wordmark rendered in Playfair Display; paired with the favicon Z-mark. |
| `assets/images/banner.jpg` | **Home hero** (circular flatlay showcase) and the **Welcome splash** visual. | Beauty-product flatlay. |
| `assets/images/test_product.jpg` | Product photography on **every** product card, PLP grid, Search Results, Wishlist, PDP main gallery + thumbnails, PDP related products, Cart line-items, and Category tiles. | The four `test_product*` images are assigned round-robin across all product slots. |
| `assets/images/test_product_2.jpg` | ″ | |
| `assets/images/test_product_3.jpg` | ″ | |
| `assets/images/test_product_4.jpg` | ″ | |

Illustration spots that are **not** product slots — OTP, Forgot Password, and
the Empty Cart empty-state — intentionally keep their icon/illustration, not a
product photo.

---

## Implementation notes

- Product imagery in the mockup is the `test_product*` set assigned round-robin;
  the Flutter app binds real catalogue media from Magento GraphQL at runtime.
- The hero and Welcome visual use the committed `banner.jpg`; swap per campaign.
- Category tiles currently reuse product photography as representative imagery —
  replace with per-category art when available.
- Currency is **AED**; all copy shown is the EN/LTR variant.
