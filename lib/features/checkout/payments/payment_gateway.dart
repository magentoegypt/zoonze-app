import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/money.dart';
import '../domain/payment_session.dart';
import 'native_payment_gateway.dart';

/// Thrown when the native payment module isn't installed yet. The caller treats
/// this as "couldn't present" → the order stays awaiting payment (not a failure
/// blamed on the customer, and never a fabricated success).
class PaymentGatewayUnavailable implements Exception {
  const PaymentGatewayUnavailable();
}

/// Hands a ready session to the native gateway SDK and resolves the outcome.
abstract interface class PaymentGateway {
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session, {
    Money? amount,
  });
}

/// Both gateways (N-Genius + Tabby) are driven through the native module, so a
/// ready session always resolves to it; a non-ready session resolves to null and
/// the caller routes by status (pending → awaiting payment; rejected/failed →
/// back to method selection).
class PaymentGatewayResolver {
  const PaymentGatewayResolver({required this.native});

  final PaymentGateway native;

  PaymentGateway? resolve(PaymentSession session) =>
      session.isReady ? native : null;
}

final paymentGatewayResolverProvider = Provider<PaymentGatewayResolver>(
  (ref) => const PaymentGatewayResolver(native: NativePaymentGateway()),
);
