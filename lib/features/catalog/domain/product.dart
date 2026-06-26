import 'money.dart';

/// Optional merchandising badge shown on a product card. Derived from catalog
/// data only — never fabricated.
enum ProductBadge { none, isNew, bestseller }

/// A catalogue product as needed for listing (home / PLP / search) and the PDP
/// summary. Richer PDP data (gallery, configurable options, variants) is added
/// in the PDP slice.
class Product {
  const Product({
    required this.sku,
    required this.name,
    required this.urlKey,
    this.brand,
    this.imageUrl,
    this.regularPrice,
    this.finalPrice,
    this.inStock = true,
    this.badge = ProductBadge.none,
  });

  final String sku;
  final String name;
  final String urlKey;
  final String? brand;
  final String? imageUrl;

  /// Catalogue (struck-through) price.
  final Money? regularPrice;

  /// Price actually charged (special price when on sale).
  final Money? finalPrice;

  final bool inStock;
  final ProductBadge badge;

  /// True when there is a genuine discount to display.
  bool get isOnSale {
    final r = regularPrice;
    final f = finalPrice;
    return r != null && f != null && f.amount < r.amount;
  }

  /// Discount percentage (rounded) or null when not on sale.
  int? get discountPercent {
    if (!isOnSale) return null;
    final r = regularPrice!.amount;
    final f = finalPrice!.amount;
    if (r <= 0) return null;
    return (((r - f) / r) * 100).round();
  }
}
