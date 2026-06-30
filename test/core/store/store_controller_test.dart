import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/error/failure.dart';
import 'package:zoonze_app/core/storage/local_cache.dart';
import 'package:zoonze_app/core/storage/locale_prefs.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/core/store/store_controller.dart';
import 'package:zoonze_app/core/store/store_repository.dart';
import 'package:zoonze_app/core/store/store_view.dart';

import '../../support/fakes.dart';

/// Fails the first `availableStores` (as a stale token would), then succeeds.
class _AuthThenOkRepository implements StoreRepository {
  _AuthThenOkRepository(this.stores);
  final List<StoreView> stores;
  int calls = 0;

  @override
  Future<List<StoreView>> fetchAvailableStores() async {
    calls++;
    if (calls == 1) throw const Failure(FailureKind.auth);
    return stores;
  }
}

ProviderContainer _container({String? persistedLocale}) {
  final container = ProviderContainer(
    overrides: [
      localCacheProvider.overrideWithValue(FakeLocalCache()),
      localePrefsProvider.overrideWithValue(FakeLocalePrefs(persistedLocale)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(kSampleStores),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('StoreController', () {
    test('seeds provisional mapping and default locale before loading', () {
      final container = _container();
      final state = container.read(storeControllerProvider);
      expect(state.activeLocale, 'en');
      expect(state.localeToCode, {'en': 'eg_en', 'ar': 'eg_ar'});
      expect(state.activeStoreCode, 'eg_en');
    });

    test('honours the persisted locale', () {
      final container = _container(persistedLocale: 'ar');
      final state = container.read(storeControllerProvider);
      expect(state.activeLocale, 'ar');
      expect(state.isRtl, isTrue);
      expect(state.activeStoreCode, 'eg_ar');
    });

    test(
      'resolves locale->code, default view and currency from availableStores',
      () async {
        final container = _container();
        await container.read(storeControllerProvider.notifier).loadStores();
        final state = container.read(storeControllerProvider);

        expect(state.stores, hasLength(2));
        expect(state.localeToCode['en'], 'eg_en');
        expect(state.localeToCode['ar'], 'eg_ar');
        expect(state.defaultLocale, 'en');
        expect(state.currency, 'AED');
      },
    );

    test('switchLocale flips the active store code', () async {
      final container = _container();
      await container.read(storeControllerProvider.notifier).loadStores();

      await container.read(storeControllerProvider.notifier).switchLocale('ar');
      final state = container.read(storeControllerProvider);

      expect(state.activeLocale, 'ar');
      expect(state.isRtl, isTrue);
      expect(state.activeStoreCode, 'eg_ar');
    });

    test('loadStores self-heals a stale token: clears it and retries as guest',
        () async {
      final tokenStore = FakeSecureTokenStore('stale-token');
      final repo = _AuthThenOkRepository(kSampleStores);
      final container = ProviderContainer(
        overrides: [
          localCacheProvider.overrideWithValue(FakeLocalCache()),
          localePrefsProvider.overrideWithValue(FakeLocalePrefs(null)),
          storeRepositoryProvider.overrideWithValue(repo),
          secureTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      await container.read(storeControllerProvider.notifier).loadStores();

      expect(repo.calls, 2, reason: 'retried once as guest after the auth fail');
      expect(await tokenStore.read(), isNull, reason: 'stale token was wiped');
      expect(container.read(storeControllerProvider).stores, hasLength(2));
    });
  });
}
