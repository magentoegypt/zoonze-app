/// Hand-written Magento 2.4.8 catalogue GraphQL documents.
///
/// These extend the Phase 0 bootstrap exception: until `tool/introspect.sh`
/// produces `schema.graphql` (origin is blocked in CI), catalogue ops are
/// hand-written + mapped. Phase 1.x migrates them to graphql_codegen.
abstract final class CatalogQueries {
  /// Top-level category tree (menu / home "shop by category").
  static const String categoryTree = r'''
query CategoryTree {
  categoryList {
    uid
    name
    url_key
    children {
      uid
      name
      url_key
      image
      include_in_menu
      product_count
    }
  }
}
''';

  /// Product listing — drives home featured, PLP, and search. `filter`/`search`
  /// are mutually optional but Magento requires at least one of them.
  static const String products = r'''
query Products(
  $search: String
  $filter: ProductAttributeFilterInput
  $sort: ProductAttributeSortInput
  $pageSize: Int!
  $currentPage: Int!
) {
  products(
    search: $search
    filter: $filter
    sort: $sort
    pageSize: $pageSize
    currentPage: $currentPage
  ) {
    total_count
    page_info {
      current_page
      total_pages
      page_size
    }
    items {
      sku
      name
      url_key
      stock_status
      image {
        url
        label
      }
      price_range {
        minimum_price {
          regular_price {
            value
            currency
          }
          final_price {
            value
            currency
          }
        }
      }
    }
    aggregations {
      attribute_code
      label
      options {
        label
        value
        count
      }
    }
  }
}
''';

  /// Single product by url_key for the PDP, including configurable options +
  /// variants, gallery, description, and review metadata.
  static const String productDetail = r'''
query ProductDetail($urlKey: String!) {
  products(filter: { url_key: { eq: $urlKey } }, pageSize: 1) {
    items {
      __typename
      sku
      name
      url_key
      stock_status
      rating_summary
      review_count
      description {
        html
      }
      image {
        url
      }
      media_gallery {
        url
        label
      }
      price_range {
        minimum_price {
          regular_price {
            value
            currency
          }
          final_price {
            value
            currency
          }
        }
      }
      ... on ConfigurableProduct {
        configurable_options {
          attribute_code
          label
          values {
            uid
            value_index
            label
            swatch_data {
              value
            }
          }
        }
        variants {
          attributes {
            code
            value_index
          }
          product {
            sku
            stock_status
            image {
              url
            }
            price_range {
              minimum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
              }
            }
          }
        }
      }
    }
  }
}
''';
}
