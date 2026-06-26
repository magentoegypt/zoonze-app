import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/config/app_config.dart';

void main() {
  group('AppConfig.current (compile-time defaults)', () {
    const config = AppConfig.current;

    test('uses sane defaults when no dart-defines are provided', () {
      expect(config.flavor, 'dev');
      expect(config.defaultLocale, 'en');
      expect(config.currency, 'AED');
      expect(config.bootstrapStoreCode, 'uae-en');
      expect(config.graphqlEndpoint, 'https://zoonze.com/graphql');
    });

    test('exposes provisional locale -> store_code fallback', () {
      expect(config.provisionalStoreCodes, {'en': 'uae-en', 'ar': 'uae-ar'});
    });

    test('isProd reflects the flavor', () {
      expect(config.isProd, isFalse);
    });
  });
}
