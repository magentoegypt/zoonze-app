import 'package:zoonze_app/core/error/failure.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/store/store_view.dart';
import 'package:zoonze_app/features/auth/data/auth_repository.dart';
import 'package:zoonze_app/features/auth/domain/customer.dart';
import 'package:zoonze_app/features/cart/data/cart_repository.dart';
import 'package:zoonze_app/features/cart/domain/cart.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/catalog/domain/aggregation.dart';
import 'package:zoonze_app/features/catalog/domain/category.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/catalog/domain/product.dart';
import 'package:zoonze_app/features/catalog/domain/product_detail.dart';
import 'package:zoonze_app/features/catalog/domain/product_page.dart';

class FakeLocalCache implements LocalCache {
  FakeLocalCache([this._stores]);
  final List<Map<String, dynamic>>? _stores;
  final Map<String, String> _kv = {};

  @override
  List<Map<String, dynamic>>? readStores() => _stores;

  @override
  Future<void> writeStores(List<Map<String, dynamic>> stores) async {}

  @override
  String? readString(String key) => _kv[key];

  @override
  Future<void> writeString(String key, String value) async => _kv[key] = value;

  @override
  Future<void> deleteKey(String key) async => _kv.remove(key);
}

class FakeLocalePrefs implements LocalePrefs {
  FakeLocalePrefs([this._value]);
  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String locale) async => _value = locale;
}

class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository(this.stores);
  final List<StoreView> stores;

  @override
  Future<List<StoreView>> fetchAvailableStores() async => stores;
}

class FakeSecureTokenStore implements SecureTokenStore {
  FakeSecureTokenStore([this._token]);
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

const Customer kSampleCustomer = Customer(
  firstName: 'Layla',
  lastName: 'Hassan',
  email: 'layla@example.com',
);

class FakeCartRepository implements CartRepository {
  Cart _cart = const Cart(id: 'guest-1');
  String? customerCart = 'customer-1';
  int createCalls = 0;
  int mergeCalls = 0;

  @override
  Future<String> createGuestCart() async {
    createCalls++;
    return 'guest-1';
  }

  @override
  Future<String?> customerCartId() async => customerCart;

  @override
  Future<Cart> getCart(String cartId) async => _cart;

  @override
  Future<Cart> addProducts(
      String cartId, List<Map<String, dynamic>> items) async {
    final sku = items.first['sku'] as String;
    final qty = (items.first['quantity'] as int?) ?? 1;
    _cart = Cart(
      id: cartId,
      items: [
        CartItem(
          uid: 'i-$sku',
          sku: sku,
          name: sku,
          quantity: qty,
          rowTotal: const Money(amount: 100, currency: 'AED'),
        ),
      ],
    );
    return _cart;
  }

  @override
  Future<Cart> updateItem(String cartId, String uid, int quantity) async {
    _cart = Cart(
      id: cartId,
      items: [
        for (final item in _cart.items)
          if (item.uid == uid)
            CartItem(
              uid: item.uid,
              sku: item.sku,
              name: item.name,
              quantity: quantity,
              rowTotal: item.rowTotal,
            )
          else
            item,
      ],
    );
    return _cart;
  }

  @override
  Future<Cart> removeItem(String cartId, String uid) async {
    _cart = Cart(
      id: cartId,
      items: _cart.items.where((i) => i.uid != uid).toList(),
    );
    return _cart;
  }

  @override
  Future<Cart> applyCoupon(String cartId, String code) async {
    _cart = Cart(
      id: cartId,
      items: _cart.items,
      totals: CartTotals(appliedCoupon: code),
    );
    return _cart;
  }

  @override
  Future<Cart> removeCoupon(String cartId) async {
    _cart = Cart(id: cartId, items: _cart.items);
    return _cart;
  }

  @override
  Future<Cart> mergeCarts(String source, String destination) async {
    mergeCalls++;
    _cart = Cart(id: destination, items: _cart.items);
    return _cart;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginFails = false, this.customer = kSampleCustomer});

  final bool loginFails;
  final Customer customer;

  @override
  Future<String> login(String email, String password) async {
    if (loginFails) throw const Failure(FailureKind.auth);
    return 'fake-token';
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> revokeToken() async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<Customer> fetchCustomer() async => customer;
}

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.categories = kSampleCategories,
    this.products = kSampleProducts,
    this.aggregations = kSampleAggregations,
  });

  final List<Category> categories;
  final List<Product> products;
  final List<Aggregation> aggregations;

  @override
  Future<List<Category>> fetchCategoryTree() async => categories;

  @override
  Future<ProductPage> fetchProducts({
    String? search,
    String? categoryUid,
    Map<String, Set<String>> attributeFilters = const {},
    ProductSortField sort = ProductSortField.relevance,
    int pageSize = 20,
    int currentPage = 1,
  }) async =>
      ProductPage(
        items: products,
        totalCount: products.length,
        currentPage: currentPage,
        totalPages: 1,
        aggregations: aggregations,
      );

  @override
  Future<ProductDetail?> fetchProductDetail(String urlKey) async => kSampleDetail;
}

const List<StoreView> kSampleStores = <StoreView>[
  StoreView(
    storeCode: 'uae-en',
    storeName: 'UAE English',
    locale: 'en_US',
    isDefault: true,
    baseCurrencyCode: 'AED',
    displayCurrencyCode: 'AED',
    baseUrl: 'https://zoonze.com/uae-en/',
    secureBaseUrl: 'https://zoonze.com/uae-en/',
    baseMediaUrl: 'https://zoonze.com/media/',
  ),
  StoreView(
    storeCode: 'uae-ar',
    storeName: 'UAE Arabic',
    locale: 'ar_SA',
    isDefault: false,
    baseCurrencyCode: 'AED',
    displayCurrencyCode: 'AED',
    baseUrl: 'https://zoonze.com/uae-ar/',
    secureBaseUrl: 'https://zoonze.com/uae-ar/',
    baseMediaUrl: 'https://zoonze.com/media/',
  ),
];

const List<Category> kSampleCategories = <Category>[
  Category(uid: 'cat-fragrance', name: 'Fragrance', urlKey: 'fragrance'),
  Category(uid: 'cat-makeup', name: 'Makeup', urlKey: 'makeup'),
];

// imageUrl is null so widget tests don't hit the network via CachedNetworkImage.
const List<Product> kSampleProducts = <Product>[
  Product(
    sku: 'CHANEL-COCO',
    name: 'Coco Mademoiselle EDP',
    urlKey: 'coco-mademoiselle',
    brand: 'Chanel',
    regularPrice: Money(amount: 250, currency: 'AED'),
    finalPrice: Money(amount: 199, currency: 'AED'),
  ),
  Product(
    sku: 'DIOR-SAUVAGE',
    name: 'Sauvage EDT',
    urlKey: 'sauvage',
    brand: 'Dior',
    regularPrice: Money(amount: 300, currency: 'AED'),
    finalPrice: Money(amount: 300, currency: 'AED'),
  ),
];

const ProductDetail kSampleDetail = ProductDetail(
  sku: 'CHANEL-COCO',
  name: 'Coco Mademoiselle EDP',
  urlKey: 'coco-mademoiselle',
  brand: 'Chanel',
  description: 'A vibrant oriental fragrance.',
  regularPrice: Money(amount: 250, currency: 'AED'),
  finalPrice: Money(amount: 199, currency: 'AED'),
  options: <ConfigurableOption>[
    ConfigurableOption(
      attributeCode: 'size',
      label: 'Size',
      values: <SwatchValue>[
        SwatchValue(valueIndex: 1, label: '50ml'),
        SwatchValue(valueIndex: 2, label: '100ml'),
      ],
    ),
  ],
  variants: <ProductVariant>[
    ProductVariant(
      sku: 'COCO-50',
      attributes: {'size': 1},
      price: Money(amount: 199, currency: 'AED'),
    ),
    ProductVariant(
      sku: 'COCO-100',
      attributes: {'size': 2},
      price: Money(amount: 299, currency: 'AED'),
    ),
  ],
);

const List<Aggregation> kSampleAggregations = <Aggregation>[
  Aggregation(
    attributeCode: 'brand',
    label: 'Brand',
    options: <AggregationOption>[
      AggregationOption(label: 'Chanel', value: '101', count: 4),
      AggregationOption(label: 'Dior', value: '102', count: 3),
    ],
  ),
];
