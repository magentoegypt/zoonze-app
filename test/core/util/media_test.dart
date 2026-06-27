import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/util/media.dart';

void main() {
  group('httpsMediaUrl', () {
    test('upgrades http to https', () {
      expect(
        httpsMediaUrl('http://zoonze.com/media/catalog/x.jpg'),
        'https://zoonze.com/media/catalog/x.jpg',
      );
    });

    test('leaves https, relative, null and empty untouched', () {
      expect(httpsMediaUrl('https://zoonze.com/media/x.jpg'),
          'https://zoonze.com/media/x.jpg');
      expect(httpsMediaUrl('/media/x.jpg'), '/media/x.jpg');
      expect(httpsMediaUrl(null), isNull);
      expect(httpsMediaUrl(''), '');
    });
  });
}
