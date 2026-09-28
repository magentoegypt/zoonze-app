import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/checkout/domain/payment_session.dart';
import 'package:zoonze_app/features/checkout/payments/tamara_payment_gateway.dart';

PaymentOutcome _classify(String url) => classifyTamaraReturn(Uri.parse(url));

void main() {
  group('classifyTamaraReturn', () {
    // The exact return paths are set by the Magento Tamara module and are not
    // in the payment contract, so this matches the conventional shapes. What
    // must hold regardless of spelling: nothing ambiguous reads as success.
    test('reads an approved return as success', () {
      expect(
        _classify('https://zoonze.com/tamara/payment/success?orderId=9'),
        PaymentOutcome.success,
      );
      expect(
        _classify('https://zoonze.com/checkout?paymentStatus=approved'),
        PaymentOutcome.success,
      );
    });

    test('reads a cancellation as cancelled', () {
      expect(
        _classify('https://zoonze.com/tamara/payment/cancel?orderId=9'),
        PaymentOutcome.cancelled,
      );
    });

    test('reads a decline as rejected, not failed', () {
      // A Tamara decline is a normal path, like Tabby's: the customer goes back
      // to method selection rather than being shown an error.
      expect(
        _classify('https://zoonze.com/tamara/payment/failure?status=declined'),
        PaymentOutcome.rejected,
      );
    });

    test('reads an explicit failure as failed', () {
      expect(
        _classify('https://zoonze.com/tamara/payment/failure'),
        PaymentOutcome.failed,
      );
    });

    test('reads an expiry as expired', () {
      expect(
        _classify('https://zoonze.com/tamara/payment/expired'),
        PaymentOutcome.expired,
      );
    });

    test('never calls an unreadable return a success', () {
      // The case that matters most: back at the store with nothing we can
      // parse. Cancelled sends the customer to CompletePaymentScreen, where
      // they can retry or pay later. Success would hand them a confirmation
      // for money that may never have moved.
      for (final url in [
        'https://zoonze.com/',
        'https://zoonze.com/checkout/onepage',
        'https://zoonze.com/tamara/payment/notify?id=abc',
      ]) {
        expect(_classify(url), PaymentOutcome.cancelled, reason: url);
      }
    });

    test('checks cancel and decline before success', () {
      // A cancel URL that still carries "success" somewhere in the path must
      // not be read as a success.
      expect(
        _classify('https://zoonze.com/checkout/success/cancel'),
        PaymentOutcome.cancelled,
      );
      expect(
        _classify('https://zoonze.com/checkout/success?status=declined'),
        PaymentOutcome.rejected,
      );
    });
  });

  group('TamaraPaymentGateway', () {
    testWidgets('refuses a session with no web_url rather than opening an empty sheet', (
      tester,
    ) async {
      const gateway = TamaraPaymentGateway(host: 'zoonze.com');
      const session = PaymentSession(
        orderNumber: '000000600',
        methodCode: 'tamara_pay_by_instalments',
        gateway: PaymentProvider.tamara,
        status: PaymentSessionStatus.ready,
      );

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(await gateway.present(ctx, session), PaymentOutcome.failed);
    });

    testWidgets('refuses when the store host is unknown', (tester) async {
      // Without it there is no way to tell a return from a payment step, so
      // presenting would risk reading a 3-D Secure page as an outcome.
      const gateway = TamaraPaymentGateway(host: '');
      const session = PaymentSession(
        orderNumber: '000000601',
        methodCode: 'tamara_pay_by_instalments',
        gateway: PaymentProvider.tamara,
        status: PaymentSessionStatus.ready,
        webUrl: 'https://checkout.tamara.co/checkout/abc',
      );

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(await gateway.present(ctx, session), PaymentOutcome.failed);
    });
  });
}
