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
final featuredProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final categories = await ref.watch(categoryTreeProvider.future);
  if (categories.isEmpty) return const <Product>[];
  final page = await ref.watch(catalogRepositoryProvider).fetchProducts(
        categoryUid: categories.first.uid,
        pageSize: 10,
      );
  return page.items;
});

/// First page of products for a category (PLP). Pagination + filters land in the
/// PLP slice; this returns page 1 with default sort.
final categoryProductsProvider =
    FutureProvider.autoDispose.family<ProductPage, String>((ref, categoryUid) {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  return ref.watch(catalogRepositoryProvider).fetchProducts(
        categoryUid: categoryUid,
        pageSize: 20,
      );
});

/// Full product detail for the PDP (by url_key). Refetches on store switch.
final productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail?, String>((ref, urlKey) {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  return ref.watch(catalogRepositoryProvider).fetchProductDetail(urlKey);
});

/// Search results for a query string (native `products(search:)`).
final searchResultsProvider =
    FutureProvider.autoDispose.family<ProductPage, String>((ref, query) {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final trimmed = query.trim();
  if (trimmed.isEmpty) return Future.value(ProductPage.empty);
  return ref.watch(catalogRepositoryProvider).fetchProducts(
        search: trimmed,
        pageSize: 20,
      );
});
