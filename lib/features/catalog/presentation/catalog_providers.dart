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

/// Products from the "New Arrivals" category (matched by url_key/name, stable
/// across locales). Empty when the catalogue has no such category — the home
/// section then hides itself rather than fabricating content.
final newArrivalsProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  Category? match;
  for (final c in categories) {
    final key = c.urlKey.toLowerCase();
    final name = c.name.toLowerCase();
    if ((key.contains('new') && key.contains('arriv')) ||
        name.contains('new arriv')) {
      match = c;
      break;
    }
  }
  if (match == null) return const <Product>[];
  final page = await ref
      .watch(catalogRepositoryProvider)
      .fetchProducts(categoryUid: match.uid, pageSize: 6);
  return page.items;
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
