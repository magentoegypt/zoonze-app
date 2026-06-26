import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/checkout/domain/tabby_config.dart';
import 'package:zoonze_app/features/checkout/payments/tabby_promo.dart';
import 'package:zoonze_app/l10n/l10n.dart';

const _aed = Money(amount: 200, currency: 'AED');

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
  group('TabbyConfig', () {
    const config = TabbyConfig(
      enabled: true,
      currency: 'AED',
      installments: 4,
      minOrderTotal: 100,
      maxOrderTotal: 5000,
    );

    test('eligibility honours enable flag, currency and bounds', () {
      expect(
        config.isEligible(const Money(amount: 200, currency: 'AED')),
        isTrue,
      );
      expect(
        config.isEligible(const Money(amount: 50, currency: 'AED')),
        isFalse,
      );
      expect(
        config.isEligible(const Money(amount: 6000, currency: 'AED')),
        isFalse,
      );
      expect(
        config.isEligible(const Money(amount: 200, currency: 'USD')),
        isFalse,
      );
      expect(
        config.copyDisabled().isEligible(
          const Money(amount: 200, currency: 'AED'),
        ),
        isFalse,
      );
    });

    test('splits the total into equal instalments', () {
      expect(
        config.perInstallment(const Money(amount: 200, currency: 'AED')),
        const Money(amount: 50, currency: 'AED'),
      );
    });
  });

  group('TabbyPromo', () {
    testWidgets('renders the Pay in 4 line when eligible', (tester) async {
      await _pump(
        tester,
        const TabbyConfig(
          enabled: true,
          currency: 'AED',
          installments: 4,
          maxOrderTotal: 5000,
        ),
        _aed,
      );
      expect(find.text('tabby'), findsOneWidget);
      expect(find.textContaining('interest-free'), findsOneWidget);
      // 200 / 4 = 50.00.
      expect(find.textContaining('AED 50.00'), findsOneWidget);
    });

    testWidgets('hides when the config is absent', (tester) async {
      await _pump(tester, null, _aed);
      expect(find.text('tabby'), findsNothing);
    });

    testWidgets('hides when the price is above the configured maximum', (
      tester,
    ) async {
      await _pump(
        tester,
        const TabbyConfig(
          enabled: true,
          currency: 'AED',
          installments: 4,
          maxOrderTotal: 100,
        ),
        _aed,
      );
      expect(find.text('tabby'), findsNothing);
    });
  });
}

extension on TabbyConfig {
  TabbyConfig copyDisabled() => TabbyConfig(
    enabled: false,
    currency: currency,
    installments: installments,
    minOrderTotal: minOrderTotal,
    maxOrderTotal: maxOrderTotal,
  );
}
