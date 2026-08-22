import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/app/deep_link_resolver_screen.dart';
import 'package:zoonze_app/app/routes.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/store/store_controller.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/widgets/web_view_screen.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../support/fakes.dart';

/// Mirrors `routerProvider`'s `errorBuilder` over stub destinations, so the test
/// exercises the same unmatched-location path an Android App Link takes without
/// pulling in every real screen.
GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.home,
  errorBuilder: (context, state) => DeepLinkResolverScreen(uri: state.uri),
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, __) => const Text('HOME')),
    GoRoute(
      path: '/product/:urlKey',
      builder: (_, s) => Text('PDP ${s.pathParameters['urlKey']}'),
    ),
    GoRoute(
      path: '/category/:uid',
      builder: (_, s) => Text('PLP ${s.pathParameters['uid']}'),
    ),
    GoRoute(
      path: AppRoutes.webview,
      builder: (_, s) => Text('WEB ${(s.extra! as WebViewArgs).url}'),
    ),
  ],
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String link,
  ({String type, String uid, String? urlKey})? resolved,
  String persistedLocale = 'en',
  bool preloadStores = true,
}) async {
  final router = _router();
  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(persistedLocale)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(kSampleStores),
      ),
      catalogRepositoryProvider.overrideWithValue(
        FakeCatalogRepository(resolved: resolved),
      ),
    ],
  );
  addTearDown(container.dispose);
  // A cold start hasn't loaded the store views yet — `bootstrap` fires
  // loadStores unawaited, and on a fresh install nothing is cached.
  if (preloadStores) {
    await container.read(storeControllerProvider.notifier).loadStores();
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  router.go(link);
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('DeepLinkResolverScreen', () {
    // CL042-DEV10: this exact URL rendered go_router's raw
    // "GoException: no routes for location" page.
    testWidgets('opens the PDP for a storefront product link', (tester) async {
      await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/fragrance/6085010044712.html',
        resolved: (type: 'PRODUCT', uid: '', urlKey: '6085010044712'),
      );

      expect(find.text('PDP 6085010044712'), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
    });

    testWidgets('leaves Home beneath so Back returns to the app', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/fragrance/6085010044712.html',
        resolved: (type: 'PRODUCT', uid: '', urlKey: '6085010044712'),
      );

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('opens the PLP for a category link', (tester) async {
      await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/fragrance.html',
        resolved: (type: 'CATEGORY', uid: 'cat-fragrance', urlKey: 'fragrance'),
      );

      expect(find.text('PLP cat-fragrance'), findsOneWidget);
    });

    testWidgets('sends an unresolvable link on our domain to the in-app '
        'WebView rather than dead-ending', (tester) async {
      await _pump(tester, link: 'https://zoonze.com/uae-en/shopbrand/');

      // go_router normalises the trailing slash off the location, so the
      // WebView receives the path without it — Magento serves both.
      expect(
        find.text('WEB https://zoonze.com/uae-en/shopbrand'),
        findsOneWidget,
      );
    });

    testWidgets('shows the branded not-found for a foreign host', (
      tester,
    ) async {
      await _pump(tester, link: 'https://example.com/uae-en/whatever.html');

      expect(find.text('Link not found'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('switches to Arabic for a /uae-ar/ link', (tester) async {
      final router = await _pump(
        tester,
        link: 'https://zoonze.com/uae-ar/fragrance/6085010044712.html',
        resolved: (type: 'PRODUCT', uid: '', urlKey: '6085010044712'),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );

      expect(container.read(storeControllerProvider).activeLocale, 'ar');
      expect(router.state.uri.path, '/product/6085010044712');
    });
    // Fresh install: `bootstrap`'s unawaited loadStores hadn't landed, so the
    // view list was empty, the `/uae-ar/` segment matched nothing, and the link
    // resolved against the default (English) store.
    testWidgets('switches to Arabic on a cold start, before the store views '
        'have loaded', (tester) async {
      final router = await _pump(
        tester,
        link: 'https://zoonze.com/uae-ar/fragrance/6085010044712.html',
        resolved: (type: 'PRODUCT', uid: '', urlKey: '6085010044712'),
        preloadStores: false,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );

      expect(container.read(storeControllerProvider).activeLocale, 'ar');
      expect(router.state.uri.path, '/product/6085010044712');
    });
  });
}
