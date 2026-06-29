import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/core/graphql/graphql_client.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/catalog/presentation/screens/home_screen.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../../support/fakes.dart';

Widget _harness(String locale) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/category/:uid', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/product/:urlKey', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/search', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/categories', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/cart', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/wishlist', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/account', builder: (_, __) => const Scaffold()),
    ],
  );
  return ProviderScope(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(locale)),
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore()),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      // Home fires storeConfig/hero/brands/footer queries — keep them offline
      // so they degrade to fallbacks without leaving retry-backoff timers.
      graphqlClientProvider.overrideWithValue(fakeGraphQLClient()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

void main() {
  // A tall surface so the lazy body list builds all sections in the test.
  Future<void> pumpHome(WidgetTester tester, String locale) async {
    await tester.binding.setSurfaceSize(const Size(1200, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness(locale));
    await tester.pumpAndSettle();
  }

  testWidgets('renders categories + product sections in English / LTR', (
    tester,
  ) async {
    await pumpHome(tester, 'en');

    // Section headers are uppercased (Figma).
    expect(find.text('SHOP BY CATEGORY'), findsWidgets);
    // New Arrivals replaced the old "Featured" section (Figma).
    expect(find.text('New Arrivals'), findsWidgets);
    expect(find.text('Fragrance'), findsWidgets);
    expect(find.text('Coco Mademoiselle EDP'), findsWidgets);

    final direction = Directionality.of(
      tester.element(find.text('Coco Mademoiselle EDP').first),
    );
    expect(direction, TextDirection.ltr);
  });

  testWidgets('renders in Arabic / RTL', (tester) async {
    await pumpHome(tester, 'ar');

    expect(find.text('تسوّق حسب الفئة'), findsWidgets);

    final direction = Directionality.of(
      tester.element(find.text('Fragrance').first),
    );
    expect(direction, TextDirection.rtl);
  });
}
