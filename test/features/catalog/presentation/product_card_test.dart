import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/catalog/presentation/widgets/product_card.dart';
import 'package:zoonze_app/l10n/l10n.dart';

import '../../../support/fakes.dart';

Widget _wrap(Widget child) => ProviderScope(
  overrides: [
    secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore()),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(child: SizedBox(width: 180, child: child)),
    ),
  ),
);

void main() {
  testWidgets(
    'shows name, sale price, struck regular price and discount badge',
    (tester) async {
      await tester.pumpWidget(
        _wrap(ProductCard(product: kSampleProducts.first)),
      );
      await tester.pump();

      expect(find.text('Coco Mademoiselle EDP'), findsOneWidget);
      expect(find.text('Chanel'), findsOneWidget);
      expect(find.text('AED 199.00'), findsOneWidget);
      expect(find.text('AED 250.00'), findsOneWidget);
      expect(find.text('-20%'), findsOneWidget);
    },
  );

  testWidgets('full-price product shows no discount badge', (tester) async {
    await tester.pumpWidget(_wrap(ProductCard(product: kSampleProducts[1])));
    await tester.pump();

    expect(find.text('AED 300.00'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
