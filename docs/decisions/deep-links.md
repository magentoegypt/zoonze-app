# Shared links & Android App Links

_Decided 2026-08-22 — ClickUp CL042-DEV10 ("Product link issue")._

**Symptom:** copying a product link in the Android app and reopening it showed
`GoException: no routes for location: https://zoonze.com/uae-en/fragrance/6085010044712.html`.
That was the *app's own* error page, not a storefront 404. Two independent
defects produced it.

## 1. `base_link_url` is the only language-carrying base

`availableStores` (verified live 2026-08-22):

| store_code | locale | `secure_base_url` | `base_link_url` |
|---|---|---|---|
| `eg_en` (default) | `en_US` | `https://zoonze.com/` | `http://zoonze.com/uae-en/` |
| `eg_ar` | `ar_SA` | `https://zoonze.com/` | `http://zoonze.com/uae-ar/` |

`secure_base_url` is identical for both views, so any URL built from it silently
resolves against the **default (English)** store. Only `base_link_url` carries
the language path — and Magento returns it as `http://`, so it must be
TLS-upgraded. Note the path segment (`uae-en`) is **not** the store code
(`eg_en`); never derive one from the other.

**Rule:** every user-facing storefront URL comes from
[`lib/core/store/store_urls.dart`](../../lib/core/store/store_urls.dart)
(`productUrl` / `storeUrl` / `storeBaseUrl`), never from ad-hoc concatenation.
Two share implementations had independently got this wrong — the PDP hardcoded
`https://zoonze.com/<url_key>`, the product card used `secure_base_url`.

## 2. `.html` is mandatory

`urlResolver` against `eg_en`, for `url_key = 6085010044712` (`url_suffix = .html`):

| queried path | result |
|---|---|
| `fragrance/6085010044712.html` | `PRODUCT` |
| `6085010044712.html` | `PRODUCT` |
| `6085010044712` | **null** |
| `uae-en/fragrance/6085010044712.html` | **null** — the store segment must be stripped first |

A suffix-less link 404s on the web *and* cannot be resolved back into the app.
`CatalogRepository._storeRelativePath` already strips the store segment.

## 3. Unmatched locations resolve instead of throwing

`AndroidManifest.xml` claims `zoonze.com` with `autoVerify`, so the OS hands
storefront URLs to Flutter — but no `GoRoute` matches a storefront path, and the
router had no `errorBuilder`. It now routes to
[`DeepLinkResolverScreen`](../../lib/app/deep_link_resolver_screen.dart), which:

1. switches language when the path carries the other view's segment (`/uae-ar/`);
2. resolves the path via `urlResolver` → PDP or PLP, reusing the same helpers as
   the home hero CTAs (`lib/features/catalog/presentation/storefront_links.dart`);
3. opens anything else on our own domain (CMS, `shopbrand`, blog) in the in-app
   `WebViewScreen`;
4. shows a branded not-found only for a foreign host.

It deliberately never hands the URL back to the browser: the app claims the
domain, so that can bounce straight back in.

It also seeds `/home` under the destination, so Back from a cold-start deep link
returns to the app rather than exiting it.

**Cold start waits for the store views.** `bootstrap.dart` fires `loadStores()`
unawaited, and on a warm install the cached views land synchronously — but on a
**fresh** install the list is empty for the first frames. Every step of the
resolution above reads it: which hosts are ours, which language the path segment
belongs to, and which `Store` header `urlResolver` runs under. A `/uae-ar/` link
opened on first launch therefore resolved against the default English store. The
resolver now awaits `StoreController.ensureStoresLoaded()` first, which returns
at once when the views are present, joins the bootstrap call when one is in
flight, and times out (5s) rather than wedging the link if the network is dead.

## 4. The intent filter is scoped

The filter previously claimed **every** `https://zoonze.com/*` path — including
`/media/*`, `/static/*`, `/rest/*` and `/graphql`. It is now limited to
`/uae-en/`, `/uae-ar/` and root-level `.html` rewrites (all three shapes exist in
`url_rewrites`), plus `www.zoonze.com`.

## Open owner dependency

Android App Links only route into the app once
`https://zoonze.com/.well-known/assetlinks.json` is published — still open in
[release.md](release.md). Until then Android shows a chooser; this fix is correct
either way, but "always opens in the app" needs that file.

iOS is unaffected by §3–4: without a `com.apple.developer.associated-domains`
entitlement, `https://` links never enter the app (only `zoonze://`). §1–2 apply
to both platforms.
