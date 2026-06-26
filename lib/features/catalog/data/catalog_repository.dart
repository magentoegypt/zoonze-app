import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/aggregation.dart';
import '../domain/category.dart';
import '../domain/money.dart';
import '../domain/product.dart';
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
    ProductSortField sort = ProductSortField.relevance,
    int pageSize = 20,
    int currentPage = 1,
  }) async {
    assert(
      (search != null && search.isNotEmpty) || categoryUid != null,
      'products query requires a non-empty search or a categoryUid',
    );
    final sortInput = _sortInput(sort);
    final variables = <String, dynamic>{
      'pageSize': pageSize,
      'currentPage': currentPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryUid != null)
        'filter': <String, dynamic>{
          'category_uid': <String, dynamic>{'eq': categoryUid},
        },
      if (sortInput != null) 'sort': sortInput,
    };
    final data = await _query(CatalogQueries.products, variables);
    final products = data['products'] as Map<String, dynamic>?;
    return products == null ? ProductPage.empty : _parseProductPage(products);
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
