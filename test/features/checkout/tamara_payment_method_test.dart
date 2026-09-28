import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/checkout/domain/checkout.dart';
import 'package:zoonze_app/features/checkout/payments/payment_order.dart';

/// Tamara went live on the store on 2026-09-28, served as
/// `tamara_pay_by_instalments`. The app renders whatever
/// `available_payment_methods` returns, so it appeared in checkout with no
/// release — which made both of these behaviours live at once.
const _tamara = PaymentMethodOption(
  code: 'tamara_pay_by_instalments',
  title: 'Tamara',
);

void main() {
  group('Tamara is a redirect method', () {
    test('never finalises on placeOrder as a cash-like method', () {
      // This is the one that mattered. isRedirect listed ngenius/tabby only,
      // so Tamara read as non-redirect and the app took the no-payment-step
      // path: Place Order went straight to order success with nothing paid.
      expect(_tamara.isRedirect, isTrue);
    });

    test('is recognised as Tamara but not as Tabby', () {
      expect(_tamara.isTamara, isTrue);
      expect(_tamara.isTabby, isFalse);
    });

    test('is not mistaken for cash on delivery', () {
      expect(isCodMethod(_tamara.code), isFalse);
    });
  });

  group('Tamara sits directly after Tabby', () {
    test('ranks between Tabby and Cash on Delivery', () {
      expect(
        paymentRank('tamara_pay_by_instalments'),
        greaterThan(paymentRank('tabby_installments')),
      );
      expect(
        paymentRank('tamara_pay_by_instalments'),
        lessThan(paymentRank('cashondelivery')),
      );
    });

    test('orders the live method list the way the client asked', () {
      // Exactly what the store returns today, deliberately shuffled — the API
      // currently lists Tamara first.
      final ordered = orderPayments(const [
        PaymentMethodOption(code: 'tamara_pay_by_instalments', title: 'Tamara'),
        PaymentMethodOption(code: 'ngeniusonline_samsungpay', title: 'Samsung'),
        PaymentMethodOption(code: 'ngeniusonline', title: 'Visa & MC'),
        PaymentMethodOption(code: 'tabby_installments', title: 'Tabby'),
        PaymentMethodOption(code: 'cashondelivery', title: 'COD'),
      ]);
      expect(ordered.map((m) => m.code).toList(), [
        'ngeniusonline_samsungpay',
        'ngeniusonline',
        'tabby_installments',
        'tamara_pay_by_instalments',
        'cashondelivery',
      ]);
    });
  });
}
