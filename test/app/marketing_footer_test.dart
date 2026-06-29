import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/app/shell/marketing_footer.dart';
import 'package:zoonze_app/core/config/store_contact.dart';
import 'package:zoonze_app/l10n/l10n.dart';

const _testContact = StoreContact(
  company: 'Zoonze Perfume & Cosmetics Trading LLC',
  address: 'HHHR Tower, Dubai, UAE',
  phone: '+971500000000',
  phoneDisplay: '+971 50 000 0000',
  email: 'info@zoonze.com',
  hours: '',
  whatsapp: 'https://wa.me/971500000000',
  website: 'https://zoonze.com',
  facebook: 'https://facebook.com/zoonze',
  instagram: 'https://instagram.com/zoonze',
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storeContactProvider.overrideWithValue(_testContact)],
      child: MaterialApp(
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
    // ABOUT US + SUPPORT columns render with tappable link rows (Figma).
    expect(find.text('About Us'), findsWidgets);
    expect(find.text('Track Order'), findsOneWidget);
    expect(find.text('Shipping & Returns'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
  });
}
