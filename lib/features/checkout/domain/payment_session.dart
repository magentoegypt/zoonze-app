/// Normalized payment outcome across every gateway (native SDK or hosted
/// redirect). Maps N-Genius `PaymentStatus`/`CardPaymentData` constants and
/// Tabby `WebViewResult` onto one set the checkout flow can reason about.
enum PaymentOutcome { success, cancelled, rejected, failed, expired }

/// Lifecycle of a provider payment session as reported by the backend resolver.
enum PaymentSessionStatus { pending, ready, failed, rejected, expired }

/// The provider session reference the app needs to present payment for an order
/// that was already placed in Magento. Populated by a backend `paymentSession`
/// resolver (Open Q §2) — see docs/decisions/payments.md. One shape serves both
/// gateways: N-Genius fills [sessionReference]/[redirectUrl] (its order ref +
/// payment-authorization link); Tabby fills [redirectUrl] (web_url),
/// [sessionReference] (payment id) and [publicKey].
class PaymentSession {
  const PaymentSession({
    required this.orderNumber,
    required this.methodCode,
    required this.status,
    this.sessionReference,
    this.redirectUrl,
    this.clientToken,
    this.publicKey,
    this.expiresAt,
    this.additionalData = const <String, String>{},
  });

  final String orderNumber;
  final String methodCode;
  final PaymentSessionStatus status;

  /// Provider order/payment reference (N-Genius order ref · Tabby payment id).
  final String? sessionReference;

  /// Hosted session URL to open in a WebView (Tabby web_url · N-Genius HPP).
  final String? redirectUrl;

  /// Short-lived access token the native SDK needs, if any.
  final String? clientToken;

  /// Provider publishable/merchant key for SDK init (Tabby).
  final String? publicKey;

  /// ISO-8601 expiry, if the provider sets one.
  final String? expiresAt;

  /// Escape hatch for provider-specific extras (e.g. Tabby available_products).
  final Map<String, String> additionalData;

  /// A session can only be presented once the backend reports it ready and has
  /// handed us something to open (a URL or a native reference).
  bool get isReady =>
      status == PaymentSessionStatus.ready &&
      (redirectUrl != null || sessionReference != null);
}
