import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/diagnostics/payment_trace.dart';
import '../../catalog/domain/money.dart';
import '../domain/payment_session.dart';
import 'payment_gateway.dart';

/// Bridges to the platform-native payment SDKs over the `zoonze/payments`
/// MethodChannel — N-Genius (`payment-sdk-android` / `NISdk`) and Tabby. The
/// native module launches the SDK, waits for its delegate/callback, and returns
/// a result map with a canonical `status` string (docs/backend/payment-contract.md).
class NativePaymentGateway implements PaymentGateway {
  const NativePaymentGateway();

  static const MethodChannel channel = MethodChannel('zoonze/payments');

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session, {
    Money? amount,
  }) async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('pay', {
        'gateway': session.gateway == PaymentProvider.tabby
            ? 'tabby'
            : 'ngenius',
        'methodCode': session.methodCode,
        'orderNumber': session.orderNumber,
        // Renders the gateway SDK's own UI in the customer's language.
        'language': Localizations.localeOf(context).languageCode,
        if (amount != null) 'amount': amount.amount,
        if (amount != null) 'currency': amount.currency,
        // N-Genius: iOS decodes the full order JSON; Android drives the href.
        'orderResponse': session.additionalData['order_response'],
        'paymentAuthorizationHref':
            session.additionalData['payment_authorization_href'] ??
            session.webUrl,
        'outletRef': session.additionalData['outlet_ref'],
        // Tabby: SDK webview on both platforms.
        'webUrl': session.webUrl,
        'publishableKey': session.publishableKey,
        'paymentId': session.paymentId,
      });
      // The native module's own status/reason, which the PaymentOutcome enum
      // cannot carry. Without it a gateway decline, an expired session and an
      // SDK error all arrive as plain "failed".
      await PaymentTrace.record(
        'native: status=${result?['status']} '
        'reference=${result?['reference']} raw=${result?['raw'] ?? "none"}',
      );
      return _mapStatus(result?['status'] as String?);
    } on MissingPluginException {
      throw const PaymentGatewayUnavailable();
    } on PlatformException catch (error) {
      await PaymentTrace.record(
        'native: PlatformException ${error.code} — ${error.message}',
      );
      return PaymentOutcome.failed;
    }
  }

  /// Maps the native module's canonical status string (see the contract table).
  PaymentOutcome _mapStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
      case 'AUTHORISED':
      case 'AUTHORIZED':
      case 'CAPTURED':
      case 'PURCHASED':
      // Post-auth review: order placed, captured asynchronously → treat as success
      // (the app re-queries order status afterwards).
      case 'POST_AUTH_REVIEW':
      case 'PAYMENT_POST_AUTH_REVIEW':
        return PaymentOutcome.success;
      case 'CANCELLED':
      case 'CANCELED':
      case 'ABORTED':
      case 'CLOSED':
        return PaymentOutcome.cancelled;
      case 'DECLINED':
      case 'AUTH_FAILED':
      case 'THREE_DS_FAILURE':
      case 'REJECTED':
        return PaymentOutcome.rejected;
      case 'EXPIRED':
        return PaymentOutcome.expired;
      default:
        return PaymentOutcome.failed;
    }
  }
}
