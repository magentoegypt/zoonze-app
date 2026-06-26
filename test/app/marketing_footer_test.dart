import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/app/shell/marketing_footer.dart';
import 'package:zoonze_app/l10n/l10n.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: MarketingFooter()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('newsletter rejects an invalid email', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pump(); // surface the snackbar
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('newsletter confirms a valid email', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'shopper@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pump();
    expect(find.text("Thanks! We'll keep you posted."), findsOneWidget);
  });

  testWidgets('footer links are tappable widgets', (tester) async {
    await _pump(tester);
    // Shop + Support headings render with tappable link rows.
    expect(find.text('Shop by category'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
  });
}
