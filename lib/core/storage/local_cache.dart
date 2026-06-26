import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Lightweight offline cache (Hive). Phase 0 caches the resolved store-view
/// list so subsequent launches don't depend on a successful bootstrap request.
/// Later phases reuse this box for cart snapshots, wishlist, and recently viewed.
class LocalCache {
  LocalCache(this._box);

  final Box<dynamic> _box;

  static const String boxName = 'zoonze_cache';
  static const String _storesKey = 'available_stores';

  static Future<LocalCache> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return LocalCache(box);
  }

  List<Map<String, dynamic>>? readStores() {
    final raw = _box.get(_storesKey);
    if (raw is! String) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> writeStores(List<Map<String, dynamic>> stores) =>
      _box.put(_storesKey, jsonEncode(stores));
}

/// Overridden in `bootstrap()` once Hive is initialised.
final localCacheProvider = Provider<LocalCache>(
  (ref) => throw UnimplementedError('localCacheProvider must be overridden in bootstrap()'),
);
