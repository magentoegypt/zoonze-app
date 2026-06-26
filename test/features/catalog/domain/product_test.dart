import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/catalog/domain/product.dart';

void main() {
  group('Money', () {
    test('formats AED with Western digits and two decimals', () {
      expect(
        const Money(amount: 199, currency: 'AED').formatted(),
        'AED 199.00',
      );
      expect(
        const Money(amount: 1250.5, currency: 'AED').formatted(),
        'AED 1,250.50',
      );
    });
  });

  group('Product pricing', () {
    test('detects a genuine discount', () {
      const product = Product(
        sku: 's',
        name: 'n',
        urlKey: 'u',
        regularPrice: Money(amount: 250, currency: 'AED'),
        finalPrice: Money(amount: 199, currency: 'AED'),
      );
      expect(product.isOnSale, isTrue);
      expect(product.discountPercent, 20); // (250-199)/250 = 20.4% -> 20
    });

    test('no discount when final equals regular', () {
      const product = Product(
        sku: 's',
        name: 'n',
        urlKey: 'u',
        regularPrice: Money(amount: 300, currency: 'AED'),
        finalPrice: Money(amount: 300, currency: 'AED'),
      );
      expect(product.isOnSale, isFalse);
      expect(product.discountPercent, isNull);
    });
  });
}
