import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/payment_session.dart';

/// Shared redirect engine for off-site gateways (N-Genius HPP, Tabby). Opens the
/// provider's URL and intercepts navigation to detect the return URL, popping
/// with a [PaymentOutcome]. The caller must re-query the order server-side
/// before trusting a success. The exact return-URL patterns come from each
/// gateway's configuration (Open Q §2) — extend [_detect] accordingly.
class PaymentRedirectScreen extends StatelessWidget {
  const PaymentRedirectScreen({super.key, required this.url});

  final String url;

  PaymentOutcome? _detect(String url) {
    final u = url.toLowerCase();
    if (u.contains('success') || u.contains('approved')) {
      return PaymentOutcome.success;
    }
    if (u.contains('cancel') || u.contains('close')) {
      return PaymentOutcome.cancelled;
    }
    if (u.contains('reject') || u.contains('declin')) {
      return PaymentOutcome.rejected;
    }
    if (u.contains('expire')) return PaymentOutcome.expired;
    if (u.contains('failure') || u.contains('failed') || u.contains('error')) {
      return PaymentOutcome.failed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentRedirectTitle)),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
        ),
        shouldOverrideUrlLoading: (controller, action) async {
          final target = action.request.url?.toString() ?? '';
          final outcome = _detect(target);
          if (outcome != null) {
            if (context.mounted) Navigator.of(context).pop(outcome);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
