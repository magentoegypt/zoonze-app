import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../catalog/domain/money.dart';
import '../domain/payment_session.dart';
import 'payment_gateway.dart';

/// Tamara BNPL checkout.
///
/// Tamara ships no Flutter package, and unlike N-Genius it needs no native
/// module either: the Magento module creates the session server-side and
/// `paymentSession` hands us a `web_url` for Tamara's hosted checkout, so this
/// renders that page in a WebView and reads the outcome from where Tamara
/// sends the customer afterwards.
///
/// **Returning to [storeHost] is the signal, not leaving Tamara's domain.**
/// A card leg can bounce through a bank's 3-D Secure page, which is neither
/// Tamara nor the store — treating "left tamara.co" as the end would abort a
/// payment mid-authentication.
class TamaraPaymentGateway implements PaymentGateway {
  const TamaraPaymentGateway({required String host}) : storeHost = host;

  /// Host of the store's own base URL (e.g. `zoonze.com`). Tamara redirects
  /// back here when the customer finishes, cancels, or is declined.
  final String storeHost;

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session, {
    Money? amount,
  }) async {
    final webUrl = session.webUrl;
    // A READY Tamara session always carries a web_url. Without one there is
    // nothing to present, and reporting failure sends the customer to
    // CompletePaymentScreen rather than showing a success they did not get.
    if (webUrl == null || webUrl.isEmpty) return PaymentOutcome.failed;
    if (storeHost.isEmpty) return PaymentOutcome.failed;

    final outcome = await Navigator.of(context).push<PaymentOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _TamaraCheckout(webUrl: webUrl, storeHost: storeHost),
      ),
    );
    // Popped without a verdict — the customer used the system back gesture or
    // the close button. A dismissal is a cancellation, never a success.
    return outcome ?? PaymentOutcome.cancelled;
  }
}

/// Classifies Tamara's return URL.
///
/// Deliberately generous about spelling and deliberately strict about success:
/// the exact return paths are set by the Magento Tamara module and are **not
/// in the payment contract**, so this matches the shapes those modules
/// conventionally use and treats anything it cannot read as *not* a success.
///
/// That asymmetry is the whole point. An unrecognised return that we call
/// cancelled sends the customer to CompletePaymentScreen, where they can retry
/// or pay later — recoverable. An unrecognised return that we called success
/// would hand them an order confirmation for money that may never have moved.
@visibleForTesting
PaymentOutcome classifyTamaraReturn(Uri uri) {
  final haystack = '${uri.path}?${uri.query}'.toLowerCase();
  bool has(String s) => haystack.contains(s);

  // Declines and cancellations are checked BEFORE success: Tamara's cancel and
  // failure URLs can still carry the word "payment" or an order id, and on
  // some modules share a path prefix with the success route.
  if (has('cancel')) return PaymentOutcome.cancelled;
  if (has('expire')) return PaymentOutcome.expired;
  if (has('declin') || has('reject')) return PaymentOutcome.rejected;
  if (has('failure') || has('failed') || has('error')) {
    return PaymentOutcome.failed;
  }
  if (has('success') || has('approved') || has('authorised') ||
      has('authorized')) {
    return PaymentOutcome.success;
  }
  // Back at the store with nothing we can read. Unknown is not success.
  return PaymentOutcome.cancelled;
}

class _TamaraCheckout extends StatefulWidget {
  const _TamaraCheckout({required this.webUrl, required this.storeHost});

  final String webUrl;
  final String storeHost;

  @override
  State<_TamaraCheckout> createState() => _TamaraCheckoutState();
}

class _TamaraCheckoutState extends State<_TamaraCheckout> {
  late final WebViewController _controller;
  int _progress = 0;

  /// Guards the pop — a redirect chain can fire several requests back to the
  /// store before the route finishes closing.
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigate,
          onProgress: (p) => setState(() => _progress = p),
        ),
      )
      ..loadRequest(Uri.parse(widget.webUrl));
  }

  NavigationDecision _onNavigate(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    // Anything that is not the store is part of the payment: Tamara itself, a
    // bank's 3-D Secure step, an app-switch back. Let it through.
    if (uri == null || uri.host != widget.storeHost) {
      return NavigationDecision.navigate;
    }
    _finish(classifyTamaraReturn(uri));
    // Never actually load the store page inside the payment sheet.
    return NavigationDecision.prevent;
  }

  void _finish(PaymentOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Closing mid-flow is a cancellation. The order stays placed and the
          // customer lands on CompletePaymentScreen to retry or pay later.
          onPressed: () => _finish(PaymentOutcome.cancelled),
        ),
        title: const Text('Tamara'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
