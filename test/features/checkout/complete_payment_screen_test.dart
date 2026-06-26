import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/checkout/data/checkout_repository.dart';
import 'package:zoonze_app/features/checkout/domain/checkout.dart';
import 'package:zoonze_app/features/checkout/domain/payment_session.dart';
import 'package:zoonze_app/features/checkout/presentation/screens/complete_payment_screen.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../support/fakes.dart';

const _methods = [
  PaymentMethodOption(code: 'ngeniusonline', title: 'Card'),
  PaymentMethodOption(code: 'tabby_checkout', title: 'Tabby'),
];

Future<FakeCheckoutRepository> _pump(
  WidgetTester tester, {
  PaymentSession? session,
  String? currentMethod = 'ngeniusonline',
  String locale = 'en',
}) async {
  final repo = FakeCheckoutRepository(paymentSession: session);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [checkoutRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompletePaymentScreen(
          args: CompletePaymentArgs(
            orderNumber: '000000123',
            methods: _methods,
            currentMethodCode: currentMethod,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows the awaiting-payment message, methods and pay-later', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.textContaining('000000123'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Tabby'), findsOneWidget);
    expect(find.text("I'll pay later"), findsOneWidget);
    // Pay now is disabled until a method is selected.
    final payNow = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Pay now'),
    );
    expect(payNow.onPressed, isNull);
  });

  testWidgets('switching to a different method calls setOrderPaymentMethod', (
    tester,
  ) async {
    // No session back → run ends "unavailable", stays on the screen.
    final repo = await _pump(tester, session: null);
    await tester.tap(find.text('Tabby')); // different from currentMethod
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay now'));
    await tester.pumpAndSettle();

    expect(repo.switchedToMethod, 'tabby_checkout');
    // Still on the complete-payment screen (no navigation on unavailable).
    expect(find.text('Pay now'), findsOneWidget);
  });

  testWidgets('retrying the SAME method recreates its session (no switch)', (
    tester,
  ) async {
    final repo = await _pump(tester, session: null);
    await tester.tap(find.text('Card')); // == currentMethod
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay now'));
    await tester.pumpAndSettle();

    expect(
      repo.switchedToMethod,
      isNull,
    ); // used fetchPaymentSession, not switch
  });

  testWidgets('renders translated + RTL in Arabic', (tester) async {
    await _pump(tester, locale: 'ar');
    expect(find.text('إتمام الدفع'), findsOneWidget); // completePaymentTitle
    expect(find.text('سأدفع لاحقًا'), findsOneWidget); // pay later
    expect(
      Directionality.of(tester.element(find.text('سأدفع لاحقًا'))),
      TextDirection.rtl,
    );
  });
}
