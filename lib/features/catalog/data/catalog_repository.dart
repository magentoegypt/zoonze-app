import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/aggregation.dart';
import '../domain/category.dart';
import '../domain/money.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';
import '../domain/product_page.dart';
import 'catalog_queries.dart';

enum ProductSortField { relevance, priceAsc, priceDesc, nameAsc, newest }

/// Reads catalogue data via GraphQL and returns domain entities (or throws a
/// [Failure]). Presentation never sees a raw GraphQL map.
class CatalogRepository {
  CatalogRepository(this._client);

  final GraphQLClient _client;

  Future<List<Category>> fetchCategoryTree() async {
    final data = await _query(CatalogQueries.categoryTree, const {});
    final roots = (data['categoryList'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseCategory)
        .toList();
    // categoryList returns the root category(ies); the browsable set is the
    // root's children when present. Hide categories flagged out of navigation.
    final source =
        (roots.isNotEmpty && roots.first.children.isNotEmpty)
            ? roots.first.children
            : roots;
    return source.where((c) => c.includeInMenu).toList(growable: false);
  }

  Future<ProductPage> fetchProducts({
    String? search,
    String? categoryUid,
    Map<String, Set<String>> attributeFilters = const {},
    ProductSortField sort = ProductSortField.relevance,
    int pageSize = 20,
    int currentPage = 1,
  }) async {
    assert(
      (search != null && search.isNotEmpty) || categoryUid != null,
      'products query requires a non-empty search or a categoryUid',
    );
    final sortInput = _sortInput(sort);
    final filter = <String, dynamic>{};
    if (categoryUid != null) {
      filter['category_uid'] = <String, dynamic>{'eq': categoryUid};
    }
    attributeFilters.forEach((code, values) {
      // 'price' uses a range input (handled separately); apply equal-type
      // filters for the rest as `{in: [...]}`.
      if (code != 'price' && values.isNotEmpty) {
        filter[code] = <String, dynamic>{'in': values.toList()};
      }
    });
    final variables = <String, dynamic>{
      'pageSize': pageSize,
      'currentPage': currentPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (filter.isNotEmpty) 'filter': filter,
      if (sortInput != null) 'sort': sortInput,
    };
    final data = await _query(CatalogQueries.products, variables);
    final products = data['products'] as Map<String, dynamic>?;
    return products == null ? ProductPage.empty : _parseProductPage(products);
  }

  /// Single product by url_key (PDP). Returns null when not found.
  Future<ProductDetail?> fetchProductDetail(String urlKey) async {
    final data = await _query(
      CatalogQueries.productDetail,
      <String, dynamic>{'urlKey': urlKey},
    );
    final items = (data['products'] as Map<String, dynamic>?)?['items']
        as List<dynamic>?;
    if (items == null || items.isEmpty) return null;
    final first = items.first;
    if (first is! Map<String, dynamic>) return null;
    return _parseProductDetail(first);
  }

  ProductDetail _parseProductDetail(Map<String, dynamic> json) {
    final minPrice =
        (json['price_range'] as Map<String, dynamic>?)?['minimum_price']
            as Map<String, dynamic>?;

    final gallery = <String>[];
    final mainImage = (json['image'] as Map<String, dynamic>?)?['url'] as String?;
    if (mainImage != null && mainImage.isNotEmpty) gallery.add(mainImage);
    for (final g in (json['media_gallery'] as List<dynamic>? ?? const [])) {
      if (g is Map<String, dynamic> && g['url'] is String) {
        gallery.add(g['url'] as String);
      }
    }

    final options = (json['configurable_options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((o) => ConfigurableOption(
              attributeCode: (o['attribute_code'] as String?) ?? '',
              label: (o['label'] as String?) ?? '',
              values: (o['values'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map((v) => SwatchValue(
                        valueIndex: (v['value_index'] as int?) ?? 0,
                        label: (v['label'] as String?) ?? '',
                        swatchColor: (v['swatch_data']
                            as Map<String, dynamic>?)?['value'] as String?,
                      ))
                  .toList(),
            ))
        .toList();

    final variants = (json['variants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((vt) {
      final attrs = <String, int>{};
      for (final a in (vt['attributes'] as List<dynamic>? ?? const [])) {
        if (a is Map<String, dynamic> && a['code'] is String) {
          attrs[a['code'] as String] = (a['value_index'] as int?) ?? 0;
        }
      }
      final product = vt['product'] as Map<String, dynamic>?;
      final variantMin =
          (product?['price_range'] as Map<String, dynamic>?)?['minimum_price']
              as Map<String, dynamic>?;
      return ProductVariant(
        sku: (product?['sku'] as String?) ?? '',
        attributes: attrs,
        price: _parseMoney(variantMin?['final_price'] as Map<String, dynamic>?),
        inStock: (product?['stock_status'] as String?) != 'OUT_OF_STOCK',
        imageUrl: (product?['image'] as Map<String, dynamic>?)?['url'] as String?,
      );
    }).toList();

    return ProductDetail(
      sku: (json['sku'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      urlKey: (json['url_key'] as String?) ?? '',
      description:
          _stripHtml((json['description'] as Map<String, dynamic>?)?['html']
              as String?),
      gallery: gallery.toSet().toList(growable: false),
      regularPrice:
          _parseMoney(minPrice?['regular_price'] as Map<String, dynamic>?),
      finalPrice: _parseMoney(minPrice?['final_price'] as Map<String, dynamic>?),
      inStock: (json['stock_status'] as String?) != 'OUT_OF_STOCK',
      options: options,
      variants: variants,
      ratingSummary: (json['rating_summary'] as int?) ?? 0,
      reviewCount: (json['review_count'] as int?) ?? 0,
    );
  }

  String? _stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    final text = html
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic>? _sortInput(ProductSortField sort) {
    switch (sort) {
      case ProductSortField.relevance:
        return null;
      case ProductSortField.priceAsc:
        return <String, dynamic>{'price': 'ASC'};
      case ProductSortField.priceDesc:
        return <String, dynamic>{'price': 'DESC'};
      case ProductSortField.nameAsc:
        return <String, dynamic>{'name': 'ASC'};
      case ProductSortField.newest:
        return <String, dynamic>{'created_at': 'DESC'};
    }
  }

  Future<Map<String, dynamic>> _query(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        throw mapOperationException(result.exception!);
      }
      return result.data ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(FailureKind.unknown, detail: error.toString());
    }
  }

  Category _parseCategory(Map<String, dynamic> json) {
    final children = (json['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseCategory)
        .toList();
    return Category(
      uid: (json['uid'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      urlKey: (json['url_key'] as String?) ?? '',
      image: json['image'] as String?,
      productCount: (json['product_count'] as int?) ?? 0,
      includeInMenu: (json['include_in_menu'] as bool?) ?? true,
      children: children,
    );
  }

  ProductPage _parseProductPage(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseProduct)
        .toList();
    final pageInfo = json['page_info'] as Map<String, dynamic>?;
    return ProductPage(
      items: items,
      totalCount: (json['total_count'] as int?) ?? items.length,
      currentPage: (pageInfo?['current_page'] as int?) ?? 1,
      totalPages: (pageInfo?['total_pages'] as int?) ?? 1,
      aggregations: _parseAggregations(json['aggregations'] as List<dynamic>?),
    );
  }

  Product _parseProduct(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final minPrice = (json['price_range'] as Map<String, dynamic>?)?['minimum_price']
        as Map<String, dynamic>?;
    return Product(
      sku: (json['sku'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      urlKey: (json['url_key'] as String?) ?? '',
      imageUrl: image?['url'] as String?,
      regularPrice:
          _parseMoney(minPrice?['regular_price'] as Map<String, dynamic>?),
      finalPrice: _parseMoney(minPrice?['final_price'] as Map<String, dynamic>?),
      inStock: (json['stock_status'] as String?) != 'OUT_OF_STOCK',
    );
  }

  Money? _parseMoney(Map<String, dynamic>? json) {
    final value = json?['value'];
    if (value is! num) return null;
    return Money(
      amount: value.toDouble(),
      currency: (json!['currency'] as String?) ?? 'AED',
    );
  }

  List<Aggregation> _parseAggregations(List<dynamic>? json) {
    if (json == null) return const [];
    return json.whereType<Map<String, dynamic>>().map((agg) {
      final options = (agg['options'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (o) => AggregationOption(
              label: (o['label'] as String?) ?? '',
              value: (o['value'] as String?) ?? '',
              count: (o['count'] as int?) ?? 0,
            ),
          )
          .toList();
      return Aggregation(
        attributeCode: (agg['attribute_code'] as String?) ?? '',
        label: (agg['label'] as String?) ?? '',
        options: options,
      );
    }).toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(graphqlClientProvider)),
);
