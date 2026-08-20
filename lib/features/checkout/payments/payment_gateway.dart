import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../catalog/domain/money.dart';
import '../domain/payment_session.dart';
import 'native_payment_gateway.dart';
import 'tabby_payment_gateway.dart';

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

/// Routes a ready session to the gateway that owns it. A non-ready session
/// resolves to null and the caller routes by status (pending → awaiting
/// payment; rejected/failed → back to method selection).
///
/// The two gateways are integrated differently and deliberately so: N-Genius
/// has no Flutter package, so it goes through the native `zoonze/payments`
/// module; Tabby publishes an official Flutter package, so it stays in Dart
/// and needs no native code on either platform.
///
/// Apple Pay and Samsung Pay do **not** appear here. They are N-Genius wallet
/// flows on the same session, selected by `PaymentSession.wallet` inside the
/// native gateway — so this switch stays two-valued and every other exhaustive
/// switch over [PaymentProvider] is untouched.
class PaymentGatewayResolver {
  const PaymentGatewayResolver({required this.native, required this.tabby});

  final PaymentGateway native;
  final PaymentGateway tabby;

  PaymentGateway? resolve(PaymentSession session) {
    if (!session.isReady) return null;
    return switch (session.gateway) {
      PaymentProvider.tabby => tabby,
      PaymentProvider.ngenius => native,
    };
  }
}

final paymentGatewayResolverProvider = Provider<PaymentGatewayResolver>(
  (ref) => PaymentGatewayResolver(
    native: NativePaymentGateway(config: ref.watch(appConfigProvider)),
    tabby: const TabbyPaymentGateway(),
  ),
);
