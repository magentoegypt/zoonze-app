# ZoonZE Beauty — Figma Design Handoff

High-fidelity mobile UI for the ZoonZE Beauty storefront (UAE · AED · EN/AR),
built to mirror the live `zoonze.com` mobile experience. This doc is the bridge
between the Figma source of truth and the Flutter implementation in this repo.

**Figma file:** https://www.figma.com/design/lxyvR0z3xERp8lw8IlPTlH/

> **Design revisions — ClickUp [86d3fk7mn](https://app.clickup.com/t/86d3fk7mn) (2026-06-26).** The Figma
> file was updated against the reviewer's checklist. Applied: onboarding screens
> removed (item 2); language switcher label `العربية` → `AR` (item 3); Home header
> action icons removed (item 6); Categories search icon removed since the page has a
> search box (item 7); cart icons removed from app-bar headers (item 8); product card
> keeps the wishlist heart with the share icon stacked beneath it (item 9); the bottom
> navigation now appears on all primary screens in both EN/LTR and AR/RTL (item 10).
> Pending the reviewer's annotated screenshots: approved-logo rollout + per-page logo
> placement (items 4–5). Out of scope for the design (code — Phase 3): payment
> integration (item 11). Item 1 ("remove selected") could not be located in the file.
> The Splash & Onboarding and Authentication sections were also merged into a single
> **01 · Splash & Authentication** section, and the remaining sections renumbered.
> The auth screens (Sign In, Sign Up, Forgot Password) now show the **vertical
> Splash — Welcome logo lockup** (Z-mark over the `ZOONZE` wordmark) centered in the
> app bar (the duplicate in-body logo on Sign In was removed), and the "Free 3-hour
> delivery across the UAE" line was removed from the Launch splash.
> The same Welcome logo lockup (scaled to fit) is now used across **all** screens —
> every nav app bar (Home, Categories, PLP, PDP, Wishlist, fixed at 52 px), the
> Menu Drawer brand header, and Cart / Checkout / Empty Cart / Order Success. Sign Up
> shows a "Create Account" heading under the logo, and Sign In / Sign Up carry a
> circular icon badge (lock / person) matching the Forgot Password style. The canvas
> sections use a uniform 200 px gap.
> On the **PDP**, the app-bar share + wishlist icons were removed and the share icon
> is now stacked directly beneath the wishlist heart on the gallery image.
> The **bottom navigation bar** appears on every primary screen. The full **marketing
> footer** (from Home — ZOONZE white logo ≈51 px, social links, About/Support columns,
> newsletter, copyright) now sits above the nav on all main content screens (EN + AR).
> Both the nav **and** the footer are intentionally omitted from the 1st-group screens
> (Splash, Welcome, Sign In/Up, Forgot Password) — they stay clean and chrome-free —
> as well as from the Menu Drawer, the Filters sheet, and the Launch splash. Canvas
> sections were resized to fit their frames and re-stacked at a uniform 200 px gap so
> nothing overlaps. On the **Notifications** screen the welcome notification reads
> "Welcome to Zoonze"; the brand stays "ZoonZE" elsewhere and the all-caps `ZOONZE`
> logo wordmark is unchanged. The **Menu Drawer** logo is centered in its header
> (close button pinned to the corner); footer logos stay left/right-aligned. Each
> page's footer has a **32 px top gap** separating it from the page content (a
> transparent spacer on Home; bottom-block offset on the other screens).

The canvas holds **27 screens** organized into four labelled sections (Figma
*Sections*), stacked top-to-bottom in app-flow order:

| # | Section | Screens |
|---|---------|---------|
| 01 | Splash & Authentication | Splash — Launch, Splash — Welcome, Sign In, Sign Up, Forgot Password |
| 02 | Home & Discovery | Home (UAE / EN), Menu Drawer (side nav), Categories, Search, Search Results, Filters (Sheet), PLP — Fragrance |
| 03 | Product · Wishlist · Cart | PDP (Coco Mademoiselle), Wishlist, Cart, Cart — Empty, Checkout, Order Success, Our Brands (Explore Brands) |
| 04 | Orders & Account | My Orders, Order Tracking, My Account, Saved Addresses, Add Address, Notifications, Help & FAQ, Edit Profile |

Sign-up collects **name, email, password only** — no mobile number and no SMS/OTP
verification step. Account details and preferences are edited on the **Edit Profile**
screen (reachable from My Account).

All device frames are **390 px** wide (iPhone logical width). Every screen exists
in two variants — **English / LTR** and a full **Arabic / RTL** mirror — laid out
as two parallel, banner-labelled column groups on the canvas: **EN · English (LTR)**
on the left and **AR · العربية (RTL)** on the right, with each language's sections
suffixed `(EN / LTR)` / `(AR / RTL)` and aligned row-by-row for side-by-side
comparison. That's **27 screens × 2 = 54 frames**.

### Arabic / RTL

The Arabic mirror of all 26 screens is generated from the LTR set:

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
- **Playfair Display Bold** — the `ZOONZE` wordmark, splash headlines, and editorial titles.

### Components

A reusable library backs every screen: app bar, page title, buttons, inputs,
chips, list rows, section headers, tab bar, toggles, and the product card
(`product-card` → full-bleed `img` photo area, gold `BESTSELLER` / red discount
badges, stacked wishlist + share actions, stacked price with bold burgundy special
+ muted struck original).

The **top app bar** carries a hamburger (opens the Menu Drawer) + favicon/`ZOONZE`
lockup on one side and an actions cluster on the other. Action icons show a small
red **count badge** (white numeral, white ring) at the corner — **cart `2`** and
**wishlist `8`** (matching the drawer's quick-stats). In the Arabic mirror the
badges sit on the opposite (top-left) corner.

---

## Brand assets → where they appear

The real brand assets committed to this repo are embedded directly into the
Figma file (raster fills) so the mockup uses live imagery, not placeholders.

| Repo asset | In the design | Notes |
|------------|---------------|-------|
| `assets/branding/favicon.ico` | The ornate **Z monogram** mark, placed immediately **before** the `ZOONZE` wordmark in the header lockup across the auth screens and primary navigation screens (Welcome, Sign In, Home, Menu Drawer, Categories, PLP, PDP, Wishlist, Cart, Checkout, My Account). | Forms the icon + wordmark lockup. |
| `assets/branding/logo.png` | The full ZoonZE logo (Z-mark + wordmark), rendered **in white on the burgundy Launch splash**. | Elsewhere the wordmark is set in Playfair Display, paired with the favicon Z-mark. |
| `assets/images/banner.jpg` | **Home hero** (circular flatlay showcase) and the **Welcome splash** visual. | Beauty-product flatlay. |
| `assets/images/test_product.jpg` | Product photography (full-bleed) on **every** product card, PLP grid, Search Results, Wishlist, the PDP main gallery + thumbnails, PDP related products, Cart line-items, and Category tiles. | The four `test_product*` images are assigned round-robin across all product slots. |
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
- **Welcome** — favicon + wordmark lockup, flatlay visual, `Get Started`, sign-in
  and guest links. Language switcher shows `EN` / `AR`.

> The three onboarding slides were removed per the design review — the flow now goes
> Launch → Welcome → Sign In.

### Global chrome
- **Bottom navigation** (Home · Categories · Cart · Wishlist · Account) is shown on
  every primary screen in both EN/LTR and AR/RTL.
- **App-bar headers** are decluttered: no cart icon, no redundant search icon on
  pages that already have a search box, and the Home header keeps only the menu
  button and the logo.

### Menu Drawer (side navigation)
- Opens from the Home hamburger; a 320 px panel over a dimmed scrim.
- **Brand header** — favicon Z-mark + `ZOONZE` wordmark lockup with a close (×).
- **Profile header** — avatar initials in a burgundy ring, name, and a gold
  `Gold Member` badge, on a blush tint.
- **Quick stats** — three tiles: Orders `12`, Wishlist `8`, Vouchers `3`.
- **SHOP** — Makeup, Skincare, Fragrance, Gift Sets, New Arrivals, Bestsellers,
  each a tinted icon chip + label + chevron.
- **ACCOUNT** — Saved Addresses, Notifications, Help & Support.
- **Footer** — `Language` toggle (`EN` | `العربية`) and `Log Out`.
- The Arabic mirror flips the panel to the right; the brand lockup stays in its
  fixed favicon→`ZOONZE` order and the close (×) moves to the left.

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
   Network, Pay later with Tabby. Each option is a selectable card (radio + full
   title/subtitle + trailing icon); **Tabby** uses its mint‑green brand chip.
5. **Order Summary** + **Complete Order**.

Each step is numbered with a burgundy circular badge (① Contact, ② Shipping,
③ Payment). Option labels fill the card width — titles and subtitles are never
truncated, in both EN and the Arabic mirror.

---

## Implementation notes

- Product imagery in the mockup is the `test_product*` set assigned round-robin;
  the Flutter app binds real catalogue media from Magento GraphQL at runtime.
- The hero and Welcome visuals use the committed `banner.jpg` / product images;
  swap per campaign.
- Category tiles currently reuse product photography as representative imagery —
  replace with per-category art when available.
- Currency is **AED**; all copy shown is the EN/LTR variant.
