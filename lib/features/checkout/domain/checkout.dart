import '../../catalog/domain/money.dart';

class ShippingMethodOption {
  const ShippingMethodOption({
    required this.carrierCode,
    required this.methodCode,
    required this.title,
    this.amount,
  });

  final String carrierCode;
  final String methodCode;
  final String title;
  final Money? amount;

  String get id => '$carrierCode|$methodCode';
}

class PaymentMethodOption {
  const PaymentMethodOption({required this.code, required this.title});

  final String code;
  final String title;

  /// Redirect (off-site) gateways need the shared WebView engine. Detected by
  /// well-known method codes; the redirect URL itself comes from the gateway
  /// extension (Open Q §2).
  bool get isRedirect {
    final c = code.toLowerCase();
    return c.contains('ngenius') ||
        c.contains('network_international') ||
        c.contains('tabby');
  }

  bool get isTabby => code.toLowerCase().contains('tabby');
}

class PlaceOrderResult {
  const PlaceOrderResult({required this.orderNumber, this.redirectUrl});

  final String orderNumber;

  /// Off-site redirect URL when the gateway extension exposes one via GraphQL.
  final String? redirectUrl;
}
