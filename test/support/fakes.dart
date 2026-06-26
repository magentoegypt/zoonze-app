import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/store/store_view.dart';

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
