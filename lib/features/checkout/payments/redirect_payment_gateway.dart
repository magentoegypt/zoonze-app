import 'package:flutter/material.dart';

import '../domain/payment_session.dart';
import '../presentation/screens/payment_redirect_screen.dart';
import 'payment_gateway.dart';

/// Presents a provider-hosted payment session (Tabby `web_url`, N-Genius HPP) in
/// an in-app WebView and resolves the outcome from the return URL. The official
/// Tabby Flutter SDK (`tabby_flutter_inapp_sdk`) — which renders the same hosted
/// session with structured result callbacks — can replace this for Tabby once
/// the dependency and its public key are wired (docs/decisions/payments.md).
class RedirectPaymentGateway implements PaymentGateway {
  const RedirectPaymentGateway();

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session,
  ) async {
    final url = session.redirectUrl;
    if (url == null) return PaymentOutcome.failed;
    final outcome = await Navigator.of(context).push<PaymentOutcome>(
      MaterialPageRoute(builder: (_) => PaymentRedirectScreen(url: url)),
    );
    // A dismissed WebView (back button) returns null — treat as a cancel.
    return outcome ?? PaymentOutcome.cancelled;
  }
}
