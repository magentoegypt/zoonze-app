import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/store/store_controller.dart';
import '../core/store/store_urls.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/web_view_screen.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/presentation/storefront_links.dart';
import '../l10n/l10n.dart';
import 'routes.dart';
import 'theme/app_colors.dart';

/// Landing point for any location the route table can't match — in practice an
/// incoming Android App Link such as
/// `https://zoonze.com/uae-en/fragrance/6085010044712.html`.
///
/// The Android manifest claims `zoonze.com`, so the OS hands these URLs to
/// Flutter, but no `GoRoute` matches a storefront path. Without this screen
/// go_router renders its raw `GoException: no routes for location: …` page —
/// the bug reported in CL042-DEV10.
///
/// Resolution order:
///  1. an Arabic/English store segment (`/uae-ar/`) switches the app language,
///     so a shared Arabic link opens in Arabic;
///  2. `urlResolver` maps the path to a PRODUCT (PDP) or CATEGORY (PLP);
///  3. anything else on our own domain (CMS pages, `shopbrand`, the blog) opens
///     in the in-app [WebViewScreen] rather than dead-ending;
///  4. only a foreign host or an unparseable URL falls through to a branded
///     not-found. It deliberately does **not** hand the URL back to the browser:
///     the app claims the domain, so that can bounce straight back here.
class DeepLinkResolverScreen extends ConsumerStatefulWidget {
  const DeepLinkResolverScreen({super.key, required this.uri});

  final Uri uri;

  @override
  ConsumerState<DeepLinkResolverScreen> createState() =>
      _DeepLinkResolverScreenState();
}

class _DeepLinkResolverScreenState
    extends ConsumerState<DeepLinkResolverScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final url = widget.uri.toString();
    if (widget.uri.host.isEmpty || !isInternalStoreUrl(ref, url)) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    // A link carrying the other store view's path segment is a link in that
    // language. Switch first so `urlResolver` and the destination screen both
    // run under the right `Store` header.
    final locale = localeForStoreUrl(ref.read(storeControllerProvider), url);
    if (locale != null &&
        locale != ref.read(storeControllerProvider).activeLocale) {
      await ref.read(storeControllerProvider.notifier).switchLocale(locale);
      if (!mounted) return;
    }

    final resolved = await ref.read(catalogRepositoryProvider).resolveUrl(url);
    if (!mounted) return;

    // Grab the router and the strings up front: `go` below tears this
    // screen down, so `context` must not be touched after it.
    final router = GoRouter.of(context);
    final title = AppLocalizations.of(context).appTitle;

    final String path;
    Object? extra;
    if (resolved != null &&
        resolved.type == 'PRODUCT' &&
        resolved.urlKey != null) {
      path = AppRoutes.product(resolved.urlKey!);
    } else if (resolved != null &&
        resolved.type == 'CATEGORY' &&
        resolved.uid.isNotEmpty) {
      path = AppRoutes.category(resolved.uid);
    } else {
      // Ours, but not a catalogue entity (CMS page, shopbrand, blog) — show
      // the real page in the in-app browser.
      path = AppRoutes.webview;
      extra = WebViewArgs(url: url, title: title);
    }

    // Seed Home underneath so Back from a deep link returns to the app
    // instead of exiting it.
    router.go(AppRoutes.home);
    // The seed must be committed before the destination goes on top. On a
    // COLD start the platform is still delivering the launch URI in this same
    // frame, and a push issued alongside it loses Home — verified on device:
    // warm links kept Home, cold ones exited to the launcher on Back.
    await WidgetsBinding.instance.endOfFrame;
    router.push(path, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_failed) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.link_off,
        title: l10n.linkNotFoundTitle,
        body: l10n.linkNotFoundBody,
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.navHome),
        ),
      ),
    );
  }
}
