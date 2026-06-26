import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_session.dart';
import 'native_payment_gateway.dart';
import 'redirect_payment_gateway.dart';

/// Presents an off-session payment for an already-placed order and resolves the
/// outcome. Implementations wrap a native SDK or a hosted-session WebView.
abstract interface class PaymentGateway {
  Future<PaymentOutcome> present(BuildContext context, PaymentSession session);
}

/// Chooses the gateway for a session: the native SDK for N-Genius cards, the
/// hosted-session WebView for Tabby/HPP redirect URLs. Returns null when the
/// backend has not surfaced a usable session yet (Open Q §2) so the caller can
/// route to the awaiting-payment screen rather than fake a card/installment UI.
class PaymentGatewayResolver {
  const PaymentGatewayResolver({required this.native, required this.redirect});

  final PaymentGateway native;
  final PaymentGateway redirect;

  PaymentGateway? resolve(PaymentSession session) {
    if (!session.isReady) return null;
    final code = session.methodCode.toLowerCase();
    final isNgenius =
        code.contains('ngenius') || code.contains('network_international');
    // N-Genius card capture runs in the native SDK and needs the order ref.
    if (isNgenius && session.sessionReference != null) return native;
    // Tabby (web_url) and any HPP fallback present a hosted session.
    if (session.redirectUrl != null) return redirect;
    return null;
  }
}

final paymentGatewayResolverProvider = Provider<PaymentGatewayResolver>(
  (ref) => const PaymentGatewayResolver(
    native: NativePaymentGateway(),
    redirect: RedirectPaymentGateway(),
  ),
);
