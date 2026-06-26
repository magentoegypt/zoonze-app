import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/store/store_view.dart';
import 'package:zoonze_app/features/catalog/data/catalog_repository.dart';
import 'package:zoonze_app/features/catalog/domain/category.dart';
import 'package:zoonze_app/features/catalog/domain/money.dart';
import 'package:zoonze_app/features/catalog/domain/product.dart';
import 'package:zoonze_app/features/catalog/domain/product_page.dart';

class FakeLocalCache implements LocalCache {
  FakeLocalCache([this._stores]);
  final List<Map<String, dynamic>>? _stores;

  @override
  List<Map<String, dynamic>>? readStores() => _stores;

  @override
  Future<void> writeStores(List<Map<String, dynamic>> stores) async {}
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

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.categories = kSampleCategories,
    this.products = kSampleProducts,
  });

  final List<Category> categories;
  final List<Product> products;

  @override
  Future<List<Category>> fetchCategoryTree() async => categories;

  @override
  Future<ProductPage> fetchProducts({
    String? search,
    String? categoryUid,
    ProductSortField sort = ProductSortField.relevance,
    int pageSize = 20,
    int currentPage = 1,
  }) async =>
      ProductPage(
        items: products,
        totalCount: products.length,
        currentPage: 1,
        totalPages: 1,
      );
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
