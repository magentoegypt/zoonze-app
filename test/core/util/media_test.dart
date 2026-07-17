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

  group('resolveMediaUrl', () {
    const base = 'https://zoonze.com/media/';

    test('passes absolute URLs through, upgrading http', () {
      expect(
        resolveMediaUrl('https://zoonze.com/media/a.png', base),
        'https://zoonze.com/media/a.png',
      );
      expect(
        resolveMediaUrl('http://zoonze.com/media/a.png', base),
        'https://zoonze.com/media/a.png',
      );
    });

    test('joins a base-relative path onto the media base', () {
      expect(
        resolveMediaUrl('default/promo.png', base),
        'https://zoonze.com/media/default/promo.png',
      );
    });

    test('resolves a root-relative path against the origin, not the media '
        'base — joining it would duplicate /media/', () {
      expect(
        resolveMediaUrl('/media/catalog/category/beauty-cat-3.webp', base),
        'https://zoonze.com/media/catalog/category/beauty-cat-3.webp',
      );
    });

    test('upgrades an http media base to https', () {
      expect(
        resolveMediaUrl('/media/a.webp', 'http://zoonze.com/media/'),
        'https://zoonze.com/media/a.webp',
      );
      expect(
        resolveMediaUrl('default/a.png', 'http://zoonze.com/media/'),
        'https://zoonze.com/media/default/a.png',
      );
    });

    test('keeps an explicit port', () {
      expect(
        resolveMediaUrl('/media/a.webp', 'https://zoonze.test:8443/media/'),
        'https://zoonze.test:8443/media/a.webp',
      );
    });

    test('degrades to empty on empty input or an unusable base', () {
      expect(resolveMediaUrl('', base), '');
      expect(resolveMediaUrl(null, base), '');
      expect(resolveMediaUrl('default/a.png', ''), '');
      expect(resolveMediaUrl('/media/a.png', 'not-a-url'), '');
    });
  });
}
