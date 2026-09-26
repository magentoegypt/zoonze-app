import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/app/routes.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/catalog/data/hero_slides_provider.dart';
import 'package:zoonze_app/features/catalog/data/home_config_provider.dart';
import 'package:zoonze_app/features/catalog/domain/home_config.dart';
import 'package:zoonze_app/features/catalog/presentation/catalog_providers.dart';
import 'package:zoonze_app/features/onboarding/presentation/intro_video_screen.dart';
import 'package:zoonze_app/features/onboarding/presentation/launch_splash_screen.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../support/fakes.dart';

/// The intro is bundled, so an encode that silently stops shipping would be
/// invisible until a user hit a black first launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntroVideoView', () {
    Widget harness({
      required VoidCallback onFinished,
      required VoidCallback onFailed,
      String locale = 'en',
    }) => MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: IntroVideoView(onFinished: onFinished, onFailed: onFailed),
    );

    testWidgets('offers Skip from the first frame, before playback', (
      tester,
    ) async {
      await tester.pumpWidget(harness(onFinished: () {}, onFailed: () {}));
      await tester.pump();
      // Not gated on the video being ready: a promo a user cannot dismiss is
      // the worst thing to put in front of them at launch.
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Skip finishes exactly once, however often it is tapped', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpWidget(
        harness(onFinished: () => finished++, onFailed: () {}),
      );
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('reports failure rather than holding a black frame', (
      tester,
    ) async {
      // There is no video platform channel under flutter_test, so initialize()
      // fails here exactly as it would on a device that cannot decode the
      // asset — the path that strands a user on first launch.
      var failed = 0;
      await tester.pumpWidget(
        harness(onFinished: () {}, onFailed: () => failed++),
      );
      await tester.pumpAndSettle();
      expect(failed, 1);
    });

    testWidgets('localizes Skip in Arabic', (tester) async {
      await tester.pumpWidget(
        harness(onFinished: () {}, onFailed: () {}, locale: 'ar'),
      );
      await tester.pump();
      expect(find.text('تخطّي'), findsOneWidget);
    });
  });

  group('LaunchSplashScreen — intro gate', () {
    Widget harness(LocalCache cache, {String? token}) {
      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (_, __) => const LaunchSplashScreen(),
          ),
          for (final p in [AppRoutes.welcome, AppRoutes.home])
            GoRoute(
              path: p,
              builder: (_, __) => Scaffold(body: Text('at $p')),
            ),
        ],
      );
      return ProviderScope(
        overrides: [
          localCacheProvider.overrideWithValue(cache),
          secureTokenStoreProvider.overrideWithValue(
            FakeSecureTokenStore(token),
          ),
          // The splash warms Home in the background; stub those so the test
          // never reaches the network.
          categoryTreeProvider.overrideWith((ref) async => []),
          homeConfigProvider.overrideWith((ref) async => HomeConfig.empty),
          heroSlidesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
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

    testWidgets('plays the intro on a first launch', (tester) async {
      await tester.pumpWidget(harness(FakeLocalCache()));
      await tester.pump();
      expect(find.byType(IntroVideoView), findsOneWidget);
      // Let the gate close so its backstop timer is cancelled before teardown.
      await tester.pumpAndSettle();
    });

    testWidgets('shows the static splash once the intro has been seen', (
      tester,
    ) async {
      final cache = FakeLocalCache();
      await cache.writeString('intro_video_seen', '2026-09-26T00:00:00.000');
      await tester.pumpWidget(harness(cache));
      await tester.pump();
      expect(find.byType(IntroVideoView), findsNothing);
      // The static branding, not a video.
      expect(find.text('BEAUTY & FRAGRANCE'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('records the intro so the next launch skips it', (
      tester,
    ) async {
      final cache = FakeLocalCache();
      await tester.pumpWidget(harness(cache));
      // Video init fails under flutter_test, which is the failure path: it must
      // still mark the intro seen, or a device that cannot decode it would meet
      // it on every single launch.
      await tester.pumpAndSettle();
      expect(cache.readString('intro_video_seen'), isNotNull);
    });

    testWidgets('a failed intro still routes on, it does not hang', (
      tester,
    ) async {
      await tester.pumpWidget(harness(FakeLocalCache()));
      await tester.pumpAndSettle();
      expect(find.text('at ${AppRoutes.welcome}'), findsOneWidget);
    });

    testWidgets('a signed-in customer still lands on Home', (tester) async {
      await tester.pumpWidget(harness(FakeLocalCache(), token: 'tok'));
      await tester.pumpAndSettle();
      expect(find.text('at ${AppRoutes.home}'), findsOneWidget);
    });
  });
}
