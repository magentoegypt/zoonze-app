import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/store/store_controller.dart';
import '../data/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';
import '../domain/product_page.dart';

/// Top-level category tree. Refetches when the active store view changes.
final categoryTreeProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  return ref.watch(catalogRepositoryProvider).fetchCategoryTree();
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

Category? _findCategory(
  List<Category> cats,
  bool Function(String key, String name) test,
) {
  for (final c in cats) {
    if (test(c.urlKey.toLowerCase(), c.name.toLowerCase())) return c;
  }
  return null;
}

/// "New Arrivals": the real category if present, otherwise the newest products
/// from the first category (sorted by created_at) — so the section always has
/// real content without fabricating it.
final newArrivalsProvider = FutureProvider.autoDispose<HomeSection>((ref) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  final repo = ref.watch(catalogRepositoryProvider);
  final match = _findCategory(
    categories,
    (k, n) => (k.contains('new') && k.contains('arriv')) ||
        n.contains('new arriv'),
  );
  final source = match ?? (categories.isEmpty ? null : categories.first);
  if (source == null) return (category: null, items: const <Product>[]);
  // The "New Arrivals" category already holds the newest products in order;
  // no created_at sort (unsupported on this store).
  final page = await repo.fetchProducts(categoryUid: source.uid, pageSize: 4);
  return (category: source, items: page.items);
});

/// "Bestsellers": products from the real Bestsellers category. Hides itself
/// when the catalogue has no such category (no fabricated ranking).
final bestsellersProvider = FutureProvider.autoDispose<HomeSection>((ref) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  final match = _findCategory(
    categories,
    (k, n) =>
        k.contains('best') || n.contains('best') || n.contains('seller'),
  );
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

/// Search results for a query string (native `products(search:)`).
final searchResultsProvider = FutureProvider.autoDispose
    .family<ProductPage, String>((ref, query) {
      ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
      final trimmed = query.trim();
      if (trimmed.isEmpty) return Future.value(ProductPage.empty);
      return ref
          .watch(catalogRepositoryProvider)
          .fetchProducts(search: trimmed, pageSize: 20);
    });
