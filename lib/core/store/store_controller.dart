import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import '../graphql/graphql_client.dart';
import '../storage/local_cache.dart';
import '../storage/locale_prefs.dart';
import '../storage/secure_token_store.dart';
import 'store_repository.dart';
import 'store_view.dart';

/// Immutable active-store state. [activeStoreCode] is what the GraphQL
/// `Store` header is set to on each request.
@immutable
class StoreState {
  const StoreState({
    required this.activeLocale,
    required this.localeToCode,
    required this.defaultLocale,
    required this.currency,
    this.stores = const <StoreView>[],
  });

  /// Active app language: `en` or `ar`.
  final String activeLocale;

  /// Resolved `language -> store_code` map (authoritative once stores load).
  final Map<String, String> localeToCode;

  final String defaultLocale;
  final String currency;
  final List<StoreView> stores;

  String get activeStoreCode =>
      localeToCode[activeLocale] ?? localeToCode[defaultLocale] ?? '';

  bool get isRtl => activeLocale == 'ar';
  Locale get locale => Locale(activeLocale);

  StoreState copyWith({
    String? activeLocale,
    Map<String, String>? localeToCode,
    String? defaultLocale,
    String? currency,
    List<StoreView>? stores,
  }) => StoreState(
    activeLocale: activeLocale ?? this.activeLocale,
    localeToCode: localeToCode ?? this.localeToCode,
    defaultLocale: defaultLocale ?? this.defaultLocale,
    currency: currency ?? this.currency,
    stores: stores ?? this.stores,
  );
}

/// Owns the active store view + locale. Resolves the real `locale -> store_code`
/// mapping from `availableStores` (bootstrapped with a default code), persists
/// the choice, and performs the **atomic switch** (persist → reset cache →
/// rebuild via state change).
class StoreController extends Notifier<StoreState> {
  @override
  StoreState build() {
    final config = ref.read(appConfigProvider);
    final persisted = ref.read(localePrefsProvider).read();
    final locale = persisted ?? config.defaultLocale;
    return StoreState(
      activeLocale: locale,
      localeToCode: config.provisionalStoreCodes,
      defaultLocale: config.defaultLocale,
      currency: config.currency,
    );
  }

  /// Loads store views: cache first (fast paint), then refreshes from the
  /// network and persists. Failures keep the provisional/cached mapping.
  ///
  /// Self-heal: a stale/expired token in secure storage makes Magento reject
  /// this very first request (`auth` — "Consumer key has expired"; or, for a
  /// malformed token, an edge `service` 403). Browsing needs no token (guest
  /// GraphQL returns 200), so on those failures we drop the token and retry
  /// once as guest, recovering in-session instead of failing every request.
  /// A plain network blip keeps the provisional/cached mapping (the token may
  /// be perfectly valid — the device is just offline).
  Future<void> loadStores() async {
    final cache = ref.read(localCacheProvider);
    final cached = cache.readStores();
    if (cached != null && cached.isNotEmpty) {
      _applyStores(cached.map(StoreView.fromJson).toList(growable: false));
    }
    try {
      await _fetchAndApplyStores(cache);
    } on Failure catch (failure) {
      final tokenRelated =
          failure.kind == FailureKind.auth ||
          failure.kind == FailureKind.service;
      if (!tokenRelated) return;
      await ref.read(secureTokenStoreProvider).clear();
      ref.invalidate(graphqlClientProvider);
      try {
        await _fetchAndApplyStores(cache);
      } on Object {
        // Still down — provisional/cached mapping remains in effect.
      }
    } on Object {
      // Non-fatal: provisional/cached mapping remains in effect.
    }
  }

  Future<void> _fetchAndApplyStores(LocalCache cache) async {
    final stores = await ref
        .read(storeRepositoryProvider)
        .fetchAvailableStores();
    if (stores.isNotEmpty) {
      _applyStores(stores);
      await cache.writeStores(
        stores.map((s) => s.toJson()).toList(growable: false),
      );
    }
  }

  void _applyStores(List<StoreView> stores) {
    final map = <String, String>{};
    String? defaultLocale;
    for (final store in stores) {
      if (store.languageCode.isEmpty || store.storeCode.isEmpty) continue;
      map[store.languageCode] = store.storeCode;
      if (store.isDefault) defaultLocale = store.languageCode;
    }
    final defaultStore = stores.firstWhere(
      (s) => s.isDefault,
      orElse: () => stores.first,
    );
    state = state.copyWith(
      stores: stores,
      localeToCode: map.isEmpty ? state.localeToCode : map,
      defaultLocale: defaultLocale ?? state.defaultLocale,
      currency: defaultStore.currency.isNotEmpty
          ? defaultStore.currency
          : state.currency,
    );
  }

  /// Atomic language/store switch: persist → reset GraphQL cache → state change
  /// (which rebuilds Directionality, router, and theme).
  Future<void> switchLocale(String locale) async {
    if (locale == state.activeLocale) return;
    await ref.read(localePrefsProvider).write(locale);
    state = state.copyWith(activeLocale: locale);
    // Recreate the client so its normalized cache is dropped and subsequent
    // queries refetch with the new `Store` header.
    ref.invalidate(graphqlClientProvider);
  }
}

final storeControllerProvider = NotifierProvider<StoreController, StoreState>(
  StoreController.new,
);
