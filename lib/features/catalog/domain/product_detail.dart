import 'money.dart';

/// One selectable value of a configurable option (e.g. a size or a colour
/// swatch). [swatchColor] is a hex string when Magento exposes swatch data.
class SwatchValue {
  const SwatchValue({
    required this.valueIndex,
    required this.label,
    this.uid,
    this.swatchColor,
  });

  final int valueIndex;
  final String label;

  /// Option-value uid used for `addProductsToCart` selected_options.
  final String? uid;
  final String? swatchColor;
}

/// A configurable attribute (e.g. `color`, `size`) with its selectable values.
class ConfigurableOption {
  const ConfigurableOption({
    required this.attributeCode,
    required this.label,
    required this.values,
  });

  final String attributeCode;
  final String label;
  final List<SwatchValue> values;
}

/// A concrete variant of a configurable product, keyed by `attribute_code ->
/// value_index`.
class ProductVariant {
  const ProductVariant({
    required this.sku,
    required this.attributes,
    this.price,
    this.inStock = true,
    this.imageUrl,
  });

  final String sku;
  final Map<String, int> attributes;
  final Money? price;
  final bool inStock;
  final String? imageUrl;
}

/// Full product detail for the PDP. Reviews degrade to an empty state when the
/// store has none (no fabricated stars).
class ProductDetail {
  const ProductDetail({
    required this.sku,
    required this.name,
    required this.urlKey,
    this.brand,
    this.description,
    this.gallery = const <String>[],
    this.regularPrice,
    this.finalPrice,
    this.inStock = true,
    this.options = const <ConfigurableOption>[],
    this.variants = const <ProductVariant>[],
    this.ratingSummary = 0,
    this.reviewCount = 0,
  });

  final String sku;
  final String name;
  final String urlKey;
  final String? brand;

  /// Plain-text description (HTML already stripped).
  final String? description;
  final List<String> gallery;
  final Money? regularPrice;
  final Money? finalPrice;
  final bool inStock;
  final List<ConfigurableOption> options;
  final List<ProductVariant> variants;

  /// 0–100 (Magento `rating_summary`).
  final int ratingSummary;
  final int reviewCount;

  bool get isConfigurable => options.isNotEmpty;
  bool get hasReviews => reviewCount > 0;

  bool get isOnSale {
    final r = regularPrice;
    final f = finalPrice;
    return r != null && f != null && f.amount < r.amount;
  }

  /// The variant matching a full attribute selection, or null if incomplete /
  /// unavailable.
  ProductVariant? variantFor(Map<String, int> selection) {
    if (selection.length != options.length) return null;
    for (final variant in variants) {
      final matches = selection.entries
          .every((e) => variant.attributes[e.key] == e.value);
      if (matches) return variant;
    }
    return null;
  }
}
