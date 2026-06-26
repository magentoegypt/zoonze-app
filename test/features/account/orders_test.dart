import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/account/data/account_repository.dart';
import 'package:zoonze_app/features/account/domain/order.dart';
import 'package:zoonze_app/features/account/presentation/screens/order_detail_screen.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/l10n/l10n.dart';

class _FakeAccountRepo implements AccountRepository {
  int calls = 0;

  @override
  Future<OrderPage> fetchOrders({int pageSize = 10, int currentPage = 1}) async {
    calls++;
    return OrderPage(
      items: [
        CustomerOrder(
          number: '00000000$currentPage',
          status: 'Processing',
          date: '2026-01-0$currentPage',
        ),
      ],
      currentPage: currentPage,
      totalPages: 2,
      totalCount: 2,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<OrdersState> _settled(ProviderContainer c) async {
  var state = c.read(ordersControllerProvider);
  while (state.isLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    state = c.read(ordersControllerProvider);
  }
  return state;
}

void main() {
  group('OrdersController pagination', () {
    test('loads the first page then appends on loadMore', () async {
      final repo = _FakeAccountRepo();
      final container = ProviderContainer(
        overrides: [accountRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(ordersControllerProvider, (_, __) {});

      var state = await _settled(container);
      expect(state.orders, hasLength(1));
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);

      await container.read(ordersControllerProvider.notifier).loadMore();
      state = container.read(ordersControllerProvider);
      expect(state.orders, hasLength(2));
      expect(state.currentPage, 2);
      expect(state.hasMore, isFalse);

      // No further pages -> loadMore is a no-op.
      await container.read(ordersControllerProvider.notifier).loadMore();
      expect(container.read(ordersControllerProvider).orders, hasLength(2));
    });
  });

  group('OrderDetailScreen', () {
    Future<void> pump(WidgetTester tester, CustomerOrder order) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrderDetailScreen(order: order),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows tracking carrier + number when shipped', (tester) async {
      await pump(
        tester,
        const CustomerOrder(
          number: '000000123',
          status: 'Complete',
          date: '2026-01-02',
          total: Money(amount: 250, currency: 'AED'),
          trackings: [
            OrderTracking(title: 'Parcel', number: 'TRK999', carrier: 'Aramex'),
          ],
        ),
      );
      expect(find.textContaining('000000123'), findsOneWidget);
      expect(find.text('TRK999'), findsOneWidget);
      expect(find.textContaining('Aramex'), findsOneWidget);
    });

    testWidgets('shows the no-tracking note when not yet shipped', (
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
  });
}
