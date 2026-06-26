import '../../catalog/domain/money.dart';
import 'tabby_config.dart';

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

  /// Which Tabby product this method is, so checkout can label it correctly.
  /// "Pay Later" codes carry `later`; any other Tabby method is "Pay in 4".
  TabbyProductType? get tabbyProduct {
    final c = code.toLowerCase();
    if (!c.contains('tabby')) return null;
    if (c.contains('later')) return TabbyProductType.payLater;
    return TabbyProductType.payIn4;
  }
}

class PlaceOrderResult {
  const PlaceOrderResult({required this.orderNumber});

  final String orderNumber;
}
