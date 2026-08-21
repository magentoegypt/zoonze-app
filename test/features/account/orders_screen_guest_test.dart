import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoonze_app/core/config/store_contact.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/account/data/account_repository.dart';
import 'package:zoonze_app/features/account/data/guest_order_store.dart';
import 'package:zoonze_app/features/account/domain/order.dart';
import 'package:zoonze_app/features/account/presentation/screens/order_tracking_screen.dart';
import 'package:zoonze_app/features/account/presentation/screens/orders_screen.dart';
import 'package:zoonze_app/features/auth/data/auth_repository.dart';
import 'package:zoonze_app/features/cart/data/cart_repository.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/wishlist/data/wishlist_repository.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../support/fakes.dart';

const _testContact = StoreContact(
  company: 'Zoonze',
  address: 'Dubai, UAE',
  phone: '+971500000000',
  phoneDisplay: '+971 50 000 0000',
  email: 'info@zoonze.com',
  hours: '',
  whatsapp: 'https://wa.me/971500000000',
  website: 'https://zoonze.com',
);

/// Counts every customer-scoped order fetch, so a test can assert the guest
/// path never touches `customer { orders }` (which is a hard 403 without a
/// bearer — the bug this screen split fixes).
class _CountingAccountRepo implements AccountRepository {
  int customerFetches = 0;
  int guestFetches = 0;

  @override
  Future<OrderPage> fetchOrders({int pageSize = 10, int currentPage = 1}) async {
    customerFetches++;
    return OrderPage.empty;
  }

  @override
  Future<CustomerOrder> fetchGuestOrderByToken(String token) async {
    guestFetches++;
    return const CustomerOrder(
      number: '000000900',
      status: 'Processing',
      date: '2026-02-01',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _harness({
  required Widget screen,
  required AccountRepository repo,
  required LocalCache cache,
  String? token,
  String locale = 'en',
}) {
  final router = GoRouter(
    initialLocation: '/orders',
    routes: [
      GoRoute(path: '/orders', builder: (_, __) => screen),
      for (final p in [
        '/home',
        '/categories',
        '/cart',
        '/wishlist',
        '/account',
        '/signin',
        '/track-order',
        '/help',
      ])
        GoRoute(path: p, builder: (_, __) => const Scaffold()),
    ],
  );
  return ProviderScope(
    overrides: [
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore(token)),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      accountRepositoryProvider.overrideWithValue(repo),
      localCacheProvider.overrideWithValue(cache),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(locale)),
      catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      storeContactProvider.overrideWithValue(_testContact),
      cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
      wishlistRepositoryProvider.overrideWithValue(FakeWishlistRepository()),
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
  group('OrdersScreen — guest', () {
    testWidgets('never queries customer { orders } and offers a lookup', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _CountingAccountRepo();
      await tester.pumpWidget(
        _harness(
          screen: const OrdersScreen(),
          repo: repo,
          cache: FakeLocalCache(),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.customerFetches, 0);
      // The old failure mode: a generic error with a Retry that never succeeds.
      expect(find.text('Something went wrong. Please try again.'), findsNothing);
      expect(find.text('Track another order'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('resolves an order remembered at checkout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cache = FakeLocalCache();
      final repo = _CountingAccountRepo();
      // Seed what CheckoutController.placeOrder() persists for a guest.
      final seed = ProviderContainer(
        overrides: [localCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(seed.dispose);
      await seed
          .read(guestOrderStoreProvider.notifier)
          .remember(const GuestOrderRef(number: '000000900', token: 'tok'));

      await tester.pumpWidget(
        _harness(screen: const OrdersScreen(), repo: repo, cache: cache),
      );
      await tester.pumpAndSettle();

      expect(repo.customerFetches, 0);
      expect(repo.guestFetches, 1);
      expect(find.textContaining('000000900'), findsWidgets);
    });
  });

  group('OrderTrackingScreen', () {
    Future<void> pump(
      WidgetTester tester,
      CustomerOrder order, {
      String locale = 'en',
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _harness(
          screen: OrderTrackingScreen(order: order),
          repo: _CountingAccountRepo(),
          cache: FakeLocalCache(),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the carrier and tracking number once shipped', (
      tester,
    ) async {
      await pump(
        tester,
        const CustomerOrder(
          number: '000000123',
          status: 'Complete',
          date: '2026-01-02',
          trackings: [
            OrderTracking(title: 'Parcel', number: 'TRK999', carrier: 'Aramex'),
          ],
        ),
      );
      expect(find.text('TRK999'), findsOneWidget);
      expect(find.textContaining('Aramex'), findsOneWidget);
    });

    testWidgets('shows the no-tracking note before a shipment exists', (
      tester,
    ) async {
      await pump(
        tester,
        const CustomerOrder(
          number: '000000124',
          status: 'Pending',
          date: '2026-01-03',
        ),
      );
      expect(
        find.text('Tracking details appear here once your order ships.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the tracking number LTR in Arabic', (tester) async {
      await pump(
        tester,
        const CustomerOrder(
          number: '000000125',
          status: 'Complete',
          date: '2026-01-04',
          trackings: [
            OrderTracking(title: '', number: 'TRK123', carrier: 'Aramex'),
          ],
        ),
        locale: 'ar',
      );
      final number = tester.widget<Text>(find.text('TRK123'));
      expect(number.textDirection, TextDirection.ltr);
    });
  });
}
