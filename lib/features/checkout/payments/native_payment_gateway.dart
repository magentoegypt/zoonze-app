import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/payment_session.dart';
import 'payment_gateway.dart';

/// Bridges to the platform-native payment SDK over a MethodChannel. The native
/// module hosts the real SDK — N-Genius `payment-sdk-android` (Android) and
/// `NISdk` (iOS) — and is added per-platform (see docs/decisions/payments.md).
///
/// Contract — `invokeMethod('pay', args)` returns a status string the host maps
/// below. Android consumes the `payment-authorization` href (`gatewayUrl`); iOS
/// the full order response. Until the native module is installed, a
/// [MissingPluginException] surfaces as a failed outcome so the order — which is
/// already placed and awaiting payment — is never shown as a fake success.
class NativePaymentGateway implements PaymentGateway {
  const NativePaymentGateway();

  static const MethodChannel channel = MethodChannel(
    'com.zoonze.shop/payments',
  );

  @override
  Future<PaymentOutcome> present(
    BuildContext context,
    PaymentSession session,
  ) async {
    try {
      final status = await channel
          .invokeMethod<String>('pay', <String, Object?>{
            'provider': 'ngenius',
            'orderNumber': session.orderNumber,
            'gatewayUrl': session.redirectUrl,
            'sessionReference': session.sessionReference,
            'clientToken': session.clientToken,
            ...session.additionalData,
          });
      return _mapStatus(status);
    } on MissingPluginException {
      // Native module not installed yet — unresolved, not the customer's fault.
      return PaymentOutcome.failed;
    } on PlatformException {
      return PaymentOutcome.failed;
    }
  }

  PaymentOutcome _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'authorised':
      case 'authorized':
      case 'captured':
        return PaymentOutcome.success;
      case 'cancelled':
      case 'canceled':
        return PaymentOutcome.cancelled;
      case 'rejected':
      case 'declined':
        return PaymentOutcome.rejected;
      case 'expired':
        return PaymentOutcome.expired;
      default:
        return PaymentOutcome.failed;
    }
  }
}
