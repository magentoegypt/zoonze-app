import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/store/store_controller.dart';
import '../data/catalog_repository.dart';
import '../domain/aggregation.dart';
import '../domain/product.dart';

/// Paged PLP state: accumulated products + aggregations + active sort/filters.
class PlpState {
  const PlpState({
    this.products = const [],
    this.aggregations = const [],
    this.selectedFilters = const {},
    this.priceFrom,
    this.priceTo,
    this.sort = ProductSortField.relevance,
    this.totalCount = 0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Product> products;
  final List<Aggregation> aggregations;
  final Map<String, Set<String>> selectedFilters;
  final double? priceFrom;
  final double? priceTo;
  final ProductSortField sort;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => currentPage < totalPages;

  bool get hasPriceFilter => priceFrom != null || priceTo != null;

  int get activeFilterCount =>
      selectedFilters.values.fold(0, (sum, values) => sum + values.length) +
      (hasPriceFilter ? 1 : 0);

  static const Object _keep = Object();

  PlpState copyWith({
    List<Product>? products,
    List<Aggregation>? aggregations,
    Map<String, Set<String>>? selectedFilters,
    Object? priceFrom = _keep,
    Object? priceTo = _keep,
    ProductSortField? sort,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _keep,
  }) => PlpState(
    products: products ?? this.products,
    aggregations: aggregations ?? this.aggregations,
    selectedFilters: selectedFilters ?? this.selectedFilters,
    priceFrom: identical(priceFrom, _keep) ? this.priceFrom : priceFrom as double?,
    priceTo: identical(priceTo, _keep) ? this.priceTo : priceTo as double?,
    sort: sort ?? this.sort,
    totalCount: totalCount ?? this.totalCount,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: identical(error, _keep) ? this.error : error,
  );
}

/// Owns one category's PLP: first-page load, append-on-scroll pagination,
/// sort and aggregation-driven filtering. Reloads on store/language switch.
class PlpController extends AutoDisposeFamilyNotifier<PlpState, String> {
  static const int _pageSize = 20;

  @override
  PlpState build(String arg) {
    ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
    Future.microtask(_loadFirst);
    return const PlpState(isLoading: true);
  }

  CatalogRepository get _repo => ref.read(catalogRepositoryProvider);

  Future<void> _loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.fetchProducts(
        categoryUid: arg,
        attributeFilters: state.selectedFilters,
        priceFrom: state.priceFrom,
        priceTo: state.priceTo,
        sort: state.sort,
        pageSize: _pageSize,
        currentPage: 1,
      );
      state = state.copyWith(
        products: page.items,
        aggregations: page.aggregations.isNotEmpty
            ? page.aggregations
            : state.aggregations,
        totalCount: page.totalCount,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.fetchProducts(
        categoryUid: arg,
        attributeFilters: state.selectedFilters,
        priceFrom: state.priceFrom,
        priceTo: state.priceTo,
        sort: state.sort,
        pageSize: _pageSize,
        currentPage: state.currentPage + 1,
      );
      state = state.copyWith(
        products: [...state.products, ...page.items],
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setSort(ProductSortField sort) {
    if (sort == state.sort) return;
    state = state.copyWith(
      sort: sort,
      products: const [],
      currentPage: 0,
      totalPages: 0,
    );
    _loadFirst();
  }

  void applyFilters(
    Map<String, Set<String>> filters, {
    double? priceFrom,
    double? priceTo,
  }) {
    state = state.copyWith(
      selectedFilters: filters,
      priceFrom: priceFrom,
      priceTo: priceTo,
      products: const [],
      currentPage: 0,
      totalPages: 0,
    );
    _loadFirst();
  }

  Future<void> refresh() => _loadFirst();
}

final plpControllerProvider = NotifierProvider.autoDispose
    .family<PlpController, PlpState, String>(PlpController.new);
