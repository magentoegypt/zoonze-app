import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/store/store_controller.dart';
import '../data/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';

/// Top-level category tree. Refetches when the active store view changes.
final categoryTreeProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  return ref.watch(catalogRepositoryProvider).fetchCategoryTree();
});

/// Resolves a single category (top-level or nested) by uid from the already
/// loaded tree — backs the sub-category drill-down without an extra fetch.
final categoryByUidProvider = FutureProvider.autoDispose
    .family<Category?, String>((ref, uid) async {
      final cats = await ref.watch(categoryTreeProvider.future);
      Category? find(List<Category> list) {
        for (final c in list) {
          if (c.uid == uid) return c;
          final nested = find(c.children);
          if (nested != null) return nested;
        }
        return null;
      }

      return find(cats);
    });

/// Featured products for the home screen — first page of the first category.
final featuredProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  if (categories.isEmpty) return const <Product>[];
  final page = await ref
      .watch(catalogRepositoryProvider)
      .fetchProducts(categoryUid: categories.first.uid, pageSize: 10);
  return page.items;
});

/// A home product section: the source category (for "See all") + its products.
typedef HomeSection = ({Category? category, List<Product> items});

/// Searches the category tree recursively (top-level + nested children) so a
/// target like `new-arrivals`/`bestsellers` is found wherever it sits.
Category? _findCategory(
  List<Category> cats,
  bool Function(String key, String name) test,
) {
  for (final c in cats) {
    if (test(c.urlKey.toLowerCase(), c.name.toLowerCase())) return c;
    final nested = _findCategory(c.children, test);
    if (nested != null) return nested;
  }
  return null;
}

/// "New Arrivals": the latest 4 products from the `new-arrivals` category.
/// Hidden when that category is absent (no fabricated content).
final newArrivalsProvider = FutureProvider.autoDispose<HomeSection>((ref) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  final match = _findCategory(categories, (k, n) => k == 'new-arrivals');
  if (match == null) return (category: null, items: const <Product>[]);
  // The category already holds the newest products in order; created_at sort
  // is unsupported on this store, so take the first 4.
  final page = await ref
      .watch(catalogRepositoryProvider)
      .fetchProducts(categoryUid: match.uid, pageSize: 4);
  return (category: match, items: page.items);
});

/// "Bestsellers": products from the `bestsellers` category. Hidden when absent.
final bestsellersProvider = FutureProvider.autoDispose<HomeSection>((ref) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  final match = _findCategory(categories, (k, n) => k == 'bestsellers');
  if (match == null) return (category: null, items: const <Product>[]);
  final page = await ref
      .watch(catalogRepositoryProvider)
      .fetchProducts(categoryUid: match.uid, pageSize: 4);
  return (category: match, items: page.items);
});

/// Full product detail for the PDP (by url_key). Refetches on store switch.
final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail?, String>((ref, urlKey) {
      ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
      return ref.watch(catalogRepositoryProvider).fetchProductDetail(urlKey);
    });

/// Review rating metadata for the "Write a review" star selector.
final reviewRatingsMetadataProvider =
    FutureProvider.autoDispose<List<ReviewRatingMetadata>>((ref) {
      ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
      return ref.watch(catalogRepositoryProvider).fetchReviewRatingsMetadata();
    });
