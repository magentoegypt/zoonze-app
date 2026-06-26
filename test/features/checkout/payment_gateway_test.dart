import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/features/checkout/domain/payment_session.dart';
import 'package:zoonze_app/features/checkout/payments/payment_gateway.dart';

class _StubGateway implements PaymentGateway {
  const _StubGateway(this.label);
  final String label;

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session,
  ) async => PaymentOutcome.success;
}

PaymentSession _session({
  required String method,
  PaymentSessionStatus status = PaymentSessionStatus.ready,
  String? ref,
  String? url,
}) => PaymentSession(
  orderNumber: '000000123',
  methodCode: method,
  status: status,
  sessionReference: ref,
  redirectUrl: url,
);

void main() {
  const resolver = PaymentGatewayResolver(
    native: _StubGateway('native'),
    redirect: _StubGateway('redirect'),
  );

  group('PaymentGatewayResolver', () {
    test('routes N-Genius with a session reference to the native gateway', () {
      final gateway = resolver.resolve(
        _session(method: 'ngenius_online', ref: 'NG-1', url: 'https://hpp'),
      );
      expect((gateway as _StubGateway?)?.label, 'native');
    });

    test('routes a redirect/Tabby session to the redirect gateway', () {
      final gateway = resolver.resolve(
        _session(method: 'tabby_checkout', url: 'https://tabby/web'),
      );
      expect((gateway as _StubGateway?)?.label, 'redirect');
    });

    test('falls back to redirect when N-Genius has only a URL (HPP)', () {
      final gateway = resolver.resolve(
        _session(method: 'ngenius_online', url: 'https://hpp'),
      );
      expect((gateway as _StubGateway?)?.label, 'redirect');
    });

    test('returns null when the session is not ready (pending backend)', () {
      final gateway = resolver.resolve(
        _session(
          method: 'tabby_checkout',
          status: PaymentSessionStatus.pending,
          url: 'https://tabby/web',
        ),
      );
      expect(gateway, isNull);
    });

    test('returns null when ready but nothing to present', () {
      final gateway = resolver.resolve(_session(method: 'tabby_checkout'));
      expect(gateway, isNull);
    });
  });

  group('PaymentSession.isReady', () {
    test('true only when ready and a URL or reference is present', () {
      expect(_session(method: 'x', url: 'https://u').isReady, isTrue);
      expect(_session(method: 'x', ref: 'R').isReady, isTrue);
      expect(_session(method: 'x').isReady, isFalse);
      expect(
        _session(
          method: 'x',
          url: 'https://u',
          status: PaymentSessionStatus.rejected,
        ).isReady,
        isFalse,
      );
    });
  });
}
