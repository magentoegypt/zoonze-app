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
  const resolver = PaymentGatewayResolver(
    native: _StubGateway('native'),
    tabby: _StubGateway('tabby'),
  );

  group('PaymentGatewayResolver', () {
    // The two gateways are integrated differently — N-Genius through the
    // native module, Tabby through its Flutter package — so a session must
    // reach the one that actually owns it.
    test('routes a READY Tabby session to the Tabby gateway', () {
      final gateway = resolver.resolve(_session());
      expect((gateway as _StubGateway?)?.label, 'tabby');
    });

    test('routes a READY N-Genius session to the native gateway', () {
      final gateway = resolver.resolve(
        _session(gateway: PaymentProvider.ngenius, method: 'ngeniusonline'),
      );
      expect((gateway as _StubGateway?)?.label, 'native');
    });

    test('routes a READY wallet session to the native gateway too', () {
      // Apple Pay and Samsung Pay are N-Genius wallets, not gateways: they must
      // resolve to the same native gateway as the card form. If someone ever
      // adds a PaymentProvider value for them, this breaks first.
      for (final method in ['ngeniusonline_applepay', 'ngeniusonline_samsungpay']) {
        final session = _session(
          gateway: PaymentProvider.ngenius,
          method: method,
        );
        expect((resolver.resolve(session) as _StubGateway?)?.label, 'native',
            reason: method);
      }
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
