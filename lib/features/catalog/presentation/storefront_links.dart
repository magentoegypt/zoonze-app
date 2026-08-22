import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/store/store_controller.dart';
import '../../../core/store/store_urls.dart';
import '../../../core/util/launch.dart';
import '../../../core/widgets/web_view_screen.dart';
import '../../../l10n/l10n.dart';
import '../data/catalog_repository.dart';
import '../data/hero_slides_provider.dart';

/// Storefront-URL -> in-app-route plumbing, shared by the home CTAs and by the
/// deep-link resolver (`DeepLinkResolverScreen`). Kept in one place so an
/// incoming app link and a hero banner resolve identically.

/// Routes a storefront CTA URL inside the app: a Magento `category/view/id/N`
/// URL maps straight to the PLP; a store-relative or same-domain friendly URL
/// (`clearance.html`, `fragrance/for-her.html`) is resolved via `urlResolver`
/// so a CATEGORY opens the PLP and a PRODUCT the PDP; anything else of ours
/// (CMS pages, `shopbrand`, the blog) opens in the in-app [WebViewScreen].
/// Only a genuinely foreign host or a non-web scheme leaves the app.
///
/// **Our own domain never goes to the platform browser.** The Android manifest
/// claims `zoonze.com`, so launching one of our links externally either bounces
/// straight back into the app (a flicker plus a redundant `urlResolver` round
/// trip) or — while `assetlinks.json` is unpublished — dumps the user in Chrome.
/// On iOS, with no associated-domains entitlement, it always ejected to Safari.
/// That was CL042-DEV19: every banner whose CTA wasn't a catalogue entity.
/// See `docs/decisions/deep-links.md`.
///
/// Shared by the hero carousel, Shop by Category, the Limited-Time Offer, the
/// editorial banners and the Exclusive Offers rail so every home CTA behaves
/// identically.
Future<void> openStorefrontUrl(
  BuildContext context,
  WidgetRef ref,
  String url, {
  String? title,
}) async {
  final uri = Uri.tryParse(url.trim());
  if (url.trim().isEmpty || uri == null) return;

  // `mailto:`, `tel:`, `whatsapp:` — the platform owns these.
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') {
    launchExternalUri(uri);
    return;
  }

  // An explicit category-id URL needs no round trip: the PLP wants the UID,
  // which is base64 of the numeric id.
  final uid = categoryUidFromUrl(url);
  if (uid != null) {
    context.push(AppRoutes.category(uid), extra: title);
    return;
  }

  if (uri.host.isNotEmpty && !isInternalStoreUrl(ref, url)) {
    launchExternalUri(uri);
    return;
  }

  // Ours, or store-relative, from here on.
  final resolved = await ref.read(catalogRepositoryProvider).resolveUrl(url);
  if (!context.mounted) return;
  if (resolved != null) {
    if (resolved.type == 'CATEGORY' && resolved.uid.isNotEmpty) {
      context.push(AppRoutes.category(resolved.uid), extra: title);
      return;
    }
    if (resolved.type == 'PRODUCT' && resolved.urlKey != null) {
      context.push(AppRoutes.product(resolved.urlKey!));
      return;
    }
  }

  // Not a catalogue entity. Show the real page in the in-app browser rather
  // than dead-ending — a relative path we can't absolutise is ignored, never
  // launched as a bare relative URI.
  final web = inAppStorefrontUrl(ref.read(storeControllerProvider), url);
  if (web == null) return;
  context.push(
    AppRoutes.webview,
    extra: WebViewArgs(
      url: web,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : AppLocalizations.of(context).appTitle,
    ),
  );
}

/// Absolute `https://` storefront URL for [url] with `webview=1` appended, or
/// null when a relative path can't be absolutised (store config not loaded).
///
/// `webview=1` lets the storefront hide its own header/footer/announcement when
/// it renders inside the app — the same flag the marketing footer sends. A
/// relative path is resolved against the active view's `base_link_url`, which
/// is the only base carrying the language segment (`/uae-ar/`); an existing
/// query string and fragment are preserved.
String? inAppStorefrontUrl(StoreState state, String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  final Uri absolute;
  if (uri.host.isNotEmpty) {
    absolute = uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;
  } else {
    final base = Uri.tryParse(storeBaseUrl(state));
    if (base == null || base.host.isEmpty) return null;
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    var path = uri.path;
    // Don't double the store segment when the path already carries it.
    if (path.startsWith(basePath)) {
      path = path.substring(basePath.length);
    } else if (path.startsWith('/')) {
      path = path.substring(1);
    }
    absolute = Uri(
      scheme: 'https',
      host: base.host,
      port: base.hasPort && base.port != 443 ? base.port : null,
      path: '$basePath$path',
      query: uri.query.isEmpty ? null : uri.query,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    );
  }

  return absolute
      .replace(
        queryParameters: <String, String>{
          ...absolute.queryParameters,
          'webview': '1',
        },
      )
      .toString();
}

/// True when [url]'s host is the storefront's own domain (so the link should
/// open inside the app, not the external browser).
bool isInternalStoreUrl(WidgetRef ref, String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return false;
  if (host == 'zoonze.com' || host.endsWith('.zoonze.com')) return true;
  for (final s in ref.read(storeControllerProvider).stores) {
    for (final base in [s.secureBaseUrl, s.baseUrl, s.baseLinkUrl]) {
      final h = Uri.tryParse(base)?.host.toLowerCase();
      if (h != null && h.isNotEmpty && h == host) return true;
    }
  }
  return false;
}
