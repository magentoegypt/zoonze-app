import '../../catalog/domain/money.dart';

/// Tabby products a merchant can enable independently in Magento config.
enum TabbyProductType { payIn4, payLater }

/// One Tabby product's backend config — enable flag + eligibility bounds. All
/// values come from Magento; nothing is hardcoded in the app.
class TabbyProduct {
  const TabbyProduct({
    required this.type,
    required this.enabled,
    this.installments = 1,
    this.minOrderTotal,
    this.maxOrderTotal,
  });

  final TabbyProductType type;
  final bool enabled;

  /// Equal payments the total is split into ("Pay in 4" → 4; "Pay Later" → 1).
  final int installments;

  /// Inclusive eligibility bounds; null means unbounded on that side.
  final double? minOrderTotal;
  final double? maxOrderTotal;

  bool isEligible(Money price, String currency) {
    if (!enabled || installments <= 0) return false;
    if (price.currency != currency) return false;
    if (minOrderTotal != null && price.amount < minOrderTotal!) return false;
    if (maxOrderTotal != null && price.amount > maxOrderTotal!) return false;
    return true;
  }

  /// Per-instalment amount for the promo (total ÷ instalments).
  Money perInstallment(Money price) =>
      Money(amount: price.amount / installments, currency: price.currency);
}

/// Tabby "Pay in 4" + "Pay Later" settings, resolved **entirely from backend
/// config** — each product's enable flag and min/max thresholds come from
/// Magento, so nothing about Tabby eligibility is hardcoded. Drives both the
/// PDP/cart promo and the checkout method labels. See docs/decisions/payments.md.
class TabbyConfig {
  const TabbyConfig({required this.currency, this.products = const []});

  final String currency;
  final List<TabbyProduct> products;

  /// Enabled products eligible for [price], in backend order.
  List<TabbyProduct> eligibleFor(Money price) =>
      products.where((p) => p.isEligible(price, currency)).toList();

  TabbyProduct? product(TabbyProductType type) {
    for (final p in products) {
      if (p.type == type) return p;
    }
    return null;
  }
}
