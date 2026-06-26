import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/checkout/domain/tabby_config.dart';
import 'package:zoonze_app/features/checkout/payments/tabby_promo.dart';
import 'package:zoonze_app/l10n/l10n.dart';

const _aed = Money(amount: 200, currency: 'AED');

TabbyProduct _payIn4({bool enabled = true, double? min, double? max = 5000}) =>
    TabbyProduct(
      type: TabbyProductType.payIn4,
      enabled: enabled,
      installments: 4,
      minOrderTotal: min,
      maxOrderTotal: max,
    );

TabbyProduct _payLater({bool enabled = true, double? min, double? max}) =>
    TabbyProduct(
      type: TabbyProductType.payLater,
      enabled: enabled,
      minOrderTotal: min,
      maxOrderTotal: max,
    );

Future<void> _pump(
  WidgetTester tester,
  TabbyConfig? config,
  Money price,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tabbyConfigProvider.overrideWith((ref) => config)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TabbyPromo(price: price)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TabbyProduct / TabbyConfig', () {
    test('per-product eligibility honours enable, currency and bounds', () {
      final p = _payIn4(min: 100, max: 5000);
      expect(
        p.isEligible(const Money(amount: 200, currency: 'AED'), 'AED'),
        isTrue,
      );
      expect(
        p.isEligible(const Money(amount: 50, currency: 'AED'), 'AED'),
        isFalse,
      );
      expect(
        p.isEligible(const Money(amount: 9000, currency: 'AED'), 'AED'),
        isFalse,
      );
      expect(
        p.isEligible(const Money(amount: 200, currency: 'USD'), 'AED'),
        isFalse,
      );
      expect(_payIn4(enabled: false).isEligible(_aed, 'AED'), isFalse);
    });

    test('eligibleFor returns only enabled, in-range products', () {
      final config = TabbyConfig(
        currency: 'AED',
        products: [_payIn4(max: 100), _payLater()],
      );
      // Pay in 4 capped at 100 → out; Pay Later unbounded → in.
      final eligible = config.eligibleFor(_aed);
      expect(eligible, hasLength(1));
      expect(eligible.single.type, TabbyProductType.payLater);
    });

    test('perInstallment splits by the product instalment count', () {
      expect(
        _payIn4().perInstallment(const Money(amount: 200, currency: 'AED')),
        const Money(amount: 50, currency: 'AED'),
      );
    });
  });

  group('TabbyPromo', () {
    testWidgets('shows a line for each enabled, eligible product', (
      tester,
    ) async {
      await _pump(
        tester,
        TabbyConfig(currency: 'AED', products: [_payIn4(), _payLater()]),
        _aed,
      );
      expect(find.text('tabby'), findsNWidgets(2));
      expect(find.textContaining('interest-free payments of'), findsOneWidget);
      expect(find.textContaining('AED 50.00'), findsOneWidget); // 200 / 4
      expect(find.textContaining('pay later'), findsOneWidget);
    });

    testWidgets('shows only Pay Later when Pay in 4 is out of range', (
      tester,
    ) async {
      await _pump(
        tester,
        TabbyConfig(
          currency: 'AED',
          products: [_payIn4(max: 100), _payLater()],
        ),
        _aed,
      );
      expect(find.text('tabby'), findsOneWidget);
      expect(find.textContaining('pay later'), findsOneWidget);
      expect(find.textContaining('interest-free payments of'), findsNothing);
    });

    testWidgets('hides entirely when nothing is enabled/configured', (
      tester,
    ) async {
      await _pump(tester, null, _aed);
      expect(find.text('tabby'), findsNothing);
    });
  });
}
