import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/app/routes.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/store/store_controller.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/widgets/web_view_screen.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/catalog/presentation/storefront_links.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../../support/fakes.dart';

/// A page whose only job is to fire [openStorefrontUrl] at [link], so the tap
/// path a home banner CTA takes can be asserted end to end.
class _CtaPage extends ConsumerWidget {
  const _CtaPage(this.link);
  final String link;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => openStorefrontUrl(context, ref, link, title: 'Slide'),
        child: const Text('TAP'),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required String link,
  ({String type, String uid, String? urlKey})? resolved,
  String locale = 'en',
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, __) => _CtaPage(link)),
      GoRoute(
        path: '/category/:uid',
        builder: (_, s) => Text('PLP ${s.pathParameters['uid']}'),
      ),
      GoRoute(
        path: '/product/:urlKey',
        builder: (_, s) => Text('PDP ${s.pathParameters['urlKey']}'),
      ),
      GoRoute(
        path: AppRoutes.webview,
        builder: (_, s) => Text('WEB ${(s.extra! as WebViewArgs).url}'),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(locale)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(kSampleStores),
      ),
      catalogRepositoryProvider.overrideWithValue(
        FakeCatalogRepository(resolved: resolved),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(storeControllerProvider.notifier).loadStores();

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
  await tester.tap(find.text('TAP'));
  await tester.pumpAndSettle();
}

/// Resolved [StoreState] with the sample views loaded, for the pure helper.
Future<StoreState> _loadedState({String locale = 'en'}) async {
  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(locale)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(kSampleStores),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(storeControllerProvider.notifier).loadStores();
  return container.read(storeControllerProvider);
}

void main() {
  group('openStorefrontUrl', () {
    // CL042-DEV19: this is the banner CTA from the ticket. `shopbrand` is a
    // third-party route with no url_rewrite entity, so `urlResolver` returns
    // null — and the old code then launched it externally, where Android's own
    // app-link filter handed it back to a router that had no matching route.
    testWidgets(
      'opens an unresolvable link on our domain in the in-app WebView '
      'instead of launching it externally',
      (tester) async {
        await _pump(
          tester,
          link: 'https://zoonze.com/uae-ar/shopbrand/Mancera.html',
        );

        expect(
          find.text(
            'WEB https://zoonze.com/uae-ar/shopbrand/Mancera.html?webview=1',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('maps a category-id URL straight to the PLP', (tester) async {
      await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/catalog/category/view/id/5/',
      );

      expect(find.text('PLP NQ=='), findsOneWidget);
    });

    testWidgets('sends a resolved PRODUCT to the PDP', (tester) async {
      await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/fragrance/coco.html',
        resolved: (type: 'PRODUCT', uid: '', urlKey: 'coco'),
      );

      expect(find.text('PDP coco'), findsOneWidget);
    });

    testWidgets('sends a resolved CATEGORY to the PLP', (tester) async {
      await _pump(
        tester,
        link: 'https://zoonze.com/uae-en/fragrance.html',
        resolved: (type: 'CATEGORY', uid: 'cat-frag', urlKey: 'fragrance'),
      );

      expect(find.text('PLP cat-frag'), findsOneWidget);
    });

    testWidgets('leaves a foreign host to the platform, navigating nowhere', (
      tester,
    ) async {
      await _pump(tester, link: 'https://example.com/campaign');

      expect(find.text('TAP'), findsOneWidget);
      expect(find.textContaining('WEB '), findsNothing);
    });

    testWidgets('resolves a store-relative CTA against base_link_url', (
      tester,
    ) async {
      await _pump(tester, link: 'shopbrand/');

      expect(
        find.text('WEB https://zoonze.com/uae-en/shopbrand/?webview=1'),
        findsOneWidget,
      );
    });
  });

  group('inAppStorefrontUrl', () {
    test('appends webview=1 and keeps an existing query', () async {
      expect(
        inAppStorefrontUrl(
          await _loadedState(),
          'https://zoonze.com/p.html?utm=x',
        ),
        'https://zoonze.com/p.html?utm=x&webview=1',
      );
    });

    test('upgrades http to https', () async {
      expect(
        inAppStorefrontUrl(await _loadedState(), 'http://zoonze.com/p.html'),
        'https://zoonze.com/p.html?webview=1',
      );
    });

    test('resolves a relative path against the active view', () async {
      expect(
        inAppStorefrontUrl(await _loadedState(locale: 'ar'), 'shopbrand/'),
        'https://zoonze.com/uae-ar/shopbrand/?webview=1',
      );
    });

    test('does not double a path that already carries the store segment', () async {
      expect(
        inAppStorefrontUrl(await _loadedState(), '/uae-en/shopbrand/'),
        'https://zoonze.com/uae-en/shopbrand/?webview=1',
      );
    });

    test('is null when store config has not loaded', () {
      const empty = StoreState(
        activeLocale: 'en',
        localeToCode: <String, String>{},
        defaultLocale: 'en',
        currency: 'AED',
      );
      expect(inAppStorefrontUrl(empty, 'shopbrand/'), isNull);
    });
  });
}
