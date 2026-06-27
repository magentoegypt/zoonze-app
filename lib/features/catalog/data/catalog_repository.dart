import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../../../core/util/media.dart';
import '../domain/aggregation.dart';
import '../domain/category.dart';
import '../domain/money.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';
import '../domain/product_page.dart';
import 'catalog_queries.dart';
import 'product_mapper.dart';

// Magento's ProductAttributeSortInput on this store exposes only name /
// position / price / relevance — there is NO created_at, so a "newest" sort
// would error the whole query.
enum ProductSortField { relevance, priceAsc, priceDesc, nameAsc }

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
    final source = (roots.isNotEmpty && roots.first.children.isNotEmpty)
        ? roots.first.children
        : roots;
    return source.where((c) => c.includeInMenu).toList(growable: false);
  }

  Future<ProductPage> fetchProducts({
    String? search,
    String? categoryUid,
    Map<String, Set<String>> attributeFilters = const {},
    double? priceFrom,
    double? priceTo,
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
      // 'price' uses a range input (handled below); apply equal-type filters
      // for the rest as `{in: [...]}`.
      if (code != 'price' && values.isNotEmpty) {
        filter[code] = <String, dynamic>{'in': values.toList()};
      }
    });
    // Magento's ProductAttributeFilterInput.price is a FilterRangeTypeInput
    // ({from, to} as strings). Send whichever bound is set.
    if (priceFrom != null || priceTo != null) {
      filter['price'] = <String, dynamic>{
        if (priceFrom != null) 'from': priceFrom.toStringAsFixed(2),
        if (priceTo != null) 'to': priceTo.toStringAsFixed(2),
      };
    }
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
    final data = await _query(CatalogQueries.productDetail, <String, dynamic>{
      'urlKey': urlKey,
    });
    final items =
        (data['products'] as Map<String, dynamic>?)?['items'] as List<dynamic>?;
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
    final mainImage = httpsMediaUrl(
      (json['image'] as Map<String, dynamic>?)?['url'] as String?,
    );
    if (mainImage != null && mainImage.isNotEmpty) gallery.add(mainImage);
    for (final g in (json['media_gallery'] as List<dynamic>? ?? const [])) {
      if (g is Map<String, dynamic> && g['url'] is String) {
        gallery.add(httpsMediaUrl(g['url'] as String)!);
      }
    }

    final options = (json['configurable_options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (o) => ConfigurableOption(
            attributeCode: (o['attribute_code'] as String?) ?? '',
            label: (o['label'] as String?) ?? '',
            values: (o['values'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (v) => SwatchValue(
                    valueIndex: (v['value_index'] as int?) ?? 0,
                    label: (v['label'] as String?) ?? '',
                    uid: v['uid'] as String?,
                    swatchColor:
                        (v['swatch_data'] as Map<String, dynamic>?)?['value']
                            as String?,
                  ),
                )
                .toList(),
          ),
        )
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
              (product?['price_range']
                      as Map<String, dynamic>?)?['minimum_price']
                  as Map<String, dynamic>?;
          return ProductVariant(
            sku: (product?['sku'] as String?) ?? '',
            attributes: attrs,
            price: _parseMoney(
              variantMin?['final_price'] as Map<String, dynamic>?,
            ),
            inStock: (product?['stock_status'] as String?) != 'OUT_OF_STOCK',
            imageUrl: httpsMediaUrl(
              (product?['image'] as Map<String, dynamic>?)?['url'] as String?,
            ),
          );
        })
        .toList();

    return ProductDetail(
      sku: (json['sku'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      urlKey: (json['url_key'] as String?) ?? '',
      description: _stripHtml(
        (json['description'] as Map<String, dynamic>?)?['html'] as String?,
      ),
      gallery: gallery.toSet().toList(growable: false),
      regularPrice: _parseMoney(
        minPrice?['regular_price'] as Map<String, dynamic>?,
      ),
      finalPrice: _parseMoney(
        minPrice?['final_price'] as Map<String, dynamic>?,
      ),
      inStock: (json['stock_status'] as String?) != 'OUT_OF_STOCK',
      options: options,
      variants: variants,
      ratingSummary: (json['rating_summary'] as int?) ?? 0,
      reviewCount: (json['review_count'] as int?) ?? 0,
      reviews:
          ((json['reviews'] as Map<String, dynamic>?)?['items']
                      as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (r) => ProductReview(
                  nickname: (r['nickname'] as String?) ?? '',
                  summary: (r['summary'] as String?) ?? '',
                  text: (r['text'] as String?) ?? '',
                  averageRating: (r['average_rating'] as num?)?.toInt() ?? 0,
                  date: (r['created_at'] as String?) ?? '',
                ),
              )
              .toList(),
    );
  }

  Future<List<ReviewRatingMetadata>> fetchReviewRatingsMetadata() async {
    final data = await _query(CatalogQueries.reviewRatingsMetadata, const {});
    final items =
        (data['productReviewRatingsMetadata']
                as Map<String, dynamic>?)?['items']
            as List<dynamic>?;
    return (items ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => ReviewRatingMetadata(
            id: m['id']?.toString() ?? '',
            name: (m['name'] as String?) ?? '',
            values: (m['values'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (v) => ReviewRatingValue(
                    valueId: v['value_id']?.toString() ?? '',
                    value: (v['value'] as num?)?.toInt() ?? 0,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Future<void> createReview({
    required String sku,
    required String nickname,
    required String summary,
    required String text,
    required String ratingId,
    required String valueId,
  }) async {
    await _mutate(CatalogQueries.createReview, {
      'input': <String, dynamic>{
        'sku': sku,
        'nickname': nickname,
        'summary': summary,
        'text': text,
        'ratings': [
          {'id': ratingId, 'value_id': valueId},
        ],
      },
    });
  }

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
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
      image: httpsMediaUrl(json['image'] as String?),
      productCount: (json['product_count'] as int?) ?? 0,
      // Magento returns include_in_menu as an Int (0/1), not a Boolean —
      // casting it `as bool` throws on real data. Accept int or bool.
      includeInMenu: _asBool(json['include_in_menu'], orElse: true),
      children: children,
    );
  }

  /// Coerces a GraphQL value to bool, tolerating Magento's Int (0/1) flags.
  bool _asBool(Object? value, {required bool orElse}) => switch (value) {
    final bool b => b,
    final num n => n != 0,
    _ => orElse,
  };

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

  Product _parseProduct(Map<String, dynamic> json) => productFromJson(json);

  Money? _parseMoney(Map<String, dynamic>? json) => moneyFromJson(json);

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
