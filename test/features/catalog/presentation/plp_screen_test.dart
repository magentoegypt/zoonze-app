import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/catalog/presentation/screens/plp_screen.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../../support/fakes.dart';

Widget _harness(String locale) {
  final router = GoRouter(
    initialLocation: '/category/cat-fragrance',
    routes: [
      GoRoute(
        path: '/category/:uid',
        builder: (_, state) =>
            PlpScreen(categoryUid: state.pathParameters['uid']!, title: 'Fragrance'),
      ),
      GoRoute(path: '/product/:urlKey', builder: (_, __) => const Scaffold()),
      for (final p in ['/home', '/categories', '/cart', '/wishlist', '/account'])
        GoRoute(path: p, builder: (_, __) => const Scaffold()),
    ],
  );
  return ProviderScope(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(locale)),
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore()),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
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
  testWidgets('PLP renders products, filter + sort controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness('en'));
    await tester.pumpAndSettle();

    expect(find.text('Fragrance'), findsWidgets);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Coco Mademoiselle EDP'), findsWidgets);
  });
}
