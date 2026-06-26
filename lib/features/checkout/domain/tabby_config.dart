import '../../catalog/domain/money.dart';

/// Tabby "Pay in 4" settings, resolved **entirely from backend config** — the
/// enable flag, currency and min/max order thresholds all come from Magento, so
/// nothing about Tabby eligibility is hardcoded in the app. Drives both checkout
/// availability and the PDP/cart promo. See docs/decisions/payments.md.
class TabbyConfig {
  const TabbyConfig({
    required this.enabled,
    required this.currency,
    this.installments = 4,
    this.minOrderTotal,
    this.maxOrderTotal,
  });

  final bool enabled;

  /// Currency the thresholds are expressed in (and the only one Tabby serves).
  final String currency;

  /// Number of equal payments (config-driven; "Pay in 4" → 4).
  final int installments;

  /// Inclusive eligibility bounds; null means unbounded on that side.
  final double? minOrderTotal;
  final double? maxOrderTotal;

  /// Whether a given price qualifies for "Pay in 4" under the backend config.
  bool isEligible(Money price) {
    if (!enabled || installments <= 0) return false;
    if (price.currency != currency) return false;
    if (minOrderTotal != null && price.amount < minOrderTotal!) return false;
    if (maxOrderTotal != null && price.amount > maxOrderTotal!) return false;
    return true;
  }

  /// The per-instalment amount shown in the promo (total ÷ instalments).
  Money perInstallment(Money price) =>
      Money(amount: price.amount / installments, currency: price.currency);
}
