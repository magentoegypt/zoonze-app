import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Magento customer token in platform secure storage only — never in
/// shared_preferences.
class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // iOS: keep the token readable after the first unlock (incl. while
            // backgrounded / right after launch). The plugin's default
            // (`whenUnlocked`) can intermittently fail to read on a locked or
            // freshly-relaunched device, which surfaces as "sign-in not
            // working" on iOS. Android keeps its default backend.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'customer_token';

  Future<String?> read() => _storage.read(key: _tokenKey);
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(),
);
