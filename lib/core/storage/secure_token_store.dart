import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Magento customer token in platform secure storage only — never in
/// shared_preferences.
class SecureTokenStore {
  // Default Keychain options. `whenUnlocked` is correct for a foreground
  // storefront — the token is only read at launch / during requests while the
  // device is unlocked. (A previous `first_unlock` override changed the
  // accessibility of existing items, which made the iOS write fail with
  // errSecDuplicateItem → "sign-in not saving token". Reverted.)
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'customer_token';

  Future<String?> read() => _storage.read(key: _tokenKey);

  /// Persist the token, deleting any prior entry first. On iOS this guarantees
  /// a clean add even if a stale Keychain item exists (e.g. one written under a
  /// different accessibility), avoiding the `errSecDuplicateItem` write failure
  /// that surfaced as "sign-in not saving token".
  Future<void> write(String token) async {
    await _storage.delete(key: _tokenKey);
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() => _storage.delete(key: _tokenKey);
}

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(),
);
