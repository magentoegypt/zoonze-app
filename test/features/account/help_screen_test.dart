import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/account/presentation/screens/help_screen.dart';
import 'package:zoonze_app/l10n/l10n.dart';

Future<void> _pump(WidgetTester tester, {String locale = 'en'}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HelpScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders FAQ questions + contact actions (EN)', (tester) async {
    await _pump(tester);
    expect(find.text('How do I track my order?'), findsOneWidget);
    expect(find.text('Email support'), findsOneWidget);
    expect(find.text('support@zoonze.com'), findsOneWidget);

    // FAQ answers are collapsed until tapped.
    expect(find.textContaining('My Orders'), findsNothing);
    await tester.tap(find.text('How do I track my order?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('My Orders'), findsOneWidget);
  });

  testWidgets('renders translated + RTL in Arabic', (tester) async {
    await _pump(tester, locale: 'ar');
    expect(find.text('كيف أتتبّع طلبي؟'), findsOneWidget); // helpQOrders
    expect(
      Directionality.of(tester.element(find.text('كيف أتتبّع طلبي؟'))),
      TextDirection.rtl,
    );
  });
}
