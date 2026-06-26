import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/checkout/domain/payment_session.dart';
import 'package:zoonze_app/features/checkout/payments/payment_gateway.dart';

class _StubGateway implements PaymentGateway {
  const _StubGateway(this.label);
  final String label;

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session, {
    Money? amount,
  }) async => PaymentOutcome.success;
}

PaymentSession _session({
  PaymentProvider gateway = PaymentProvider.tabby,
  PaymentSessionStatus status = PaymentSessionStatus.ready,
  String method = 'tabby_checkout',
}) => PaymentSession(
  orderNumber: '000000123',
  methodCode: method,
  gateway: gateway,
  status: status,
);

void main() {
  const resolver = PaymentGatewayResolver(native: _StubGateway('native'));

  group('PaymentGatewayResolver', () {
    test('routes a READY session to the native gateway', () {
      final gateway = resolver.resolve(_session());
      expect((gateway as _StubGateway?)?.label, 'native');
    });

    test('returns null for any non-ready session', () {
      for (final status in [
        PaymentSessionStatus.pending,
        PaymentSessionStatus.rejected,
        PaymentSessionStatus.failed,
      ]) {
        expect(
          resolver.resolve(_session(status: status)),
          isNull,
          reason: '$status',
        );
      }
    });
  });

  group('PaymentSession.isReady', () {
    test('is exactly status == READY (per the contract)', () {
      expect(_session(status: PaymentSessionStatus.ready).isReady, isTrue);
      expect(_session(status: PaymentSessionStatus.pending).isReady, isFalse);
      expect(_session(status: PaymentSessionStatus.rejected).isReady, isFalse);
      expect(_session(status: PaymentSessionStatus.failed).isReady, isFalse);
    });
  });
}
