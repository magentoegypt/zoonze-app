import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/widgets/web_view_screen.dart';

/// The in-app browser must not become a general-purpose browser: that is a bad
/// experience (our chrome over someone else's site) and, to Apple,
/// "unrestricted web access", which forces a 17+ age rating. See
/// docs/appstore/app-information.md.
void main() {
  const allowed = 'zoonze.com';

  bool stays(String url, {bool isMainFrame = true}) => staysInApp(
    url: url,
    isMainFrame: isMainFrame,
    allowedDomain: allowed,
  );

  group('registrableDomain', () {
    test('reduces a host to its last two labels', () {
      expect(registrableDomain('www.zoonze.com'), 'zoonze.com');
      expect(registrableDomain('uae-en.zoonze.com'), 'zoonze.com');
      expect(registrableDomain('zoonze.com'), 'zoonze.com');
    });

    test('is case-insensitive', () {
      expect(registrableDomain('WWW.Zoonze.COM'), 'zoonze.com');
    });
  });

  group('staysInApp', () {
    test('keeps the store and its subdomains in the app', () {
      expect(stays('https://zoonze.com/uae-en/about-us'), isTrue);
      expect(stays('https://www.zoonze.com/uae-ar/faq'), isTrue);
      expect(stays('http://zoonze.com/terms'), isTrue);
    });

    test('sends other sites to the platform browser', () {
      expect(stays('https://instagram.com/zoonze'), isFalse);
      expect(stays('https://google.com'), isFalse);
    });

    // The whole point of the guard: a lookalike host must not read as ours.
    test('is not fooled by a host that merely contains the domain', () {
      expect(stays('https://zoonze.com.evil.example'), isFalse);
      expect(stays('https://notzoonze.com'), isFalse);
    });

    test('hands non-http schemes to the platform', () {
      expect(stays('mailto:hello@zoonze.com'), isFalse);
      expect(stays('tel:+97141234567'), isFalse);
    });

    test('never blocks sub-frames, whatever the host', () {
      // Embedded maps/video inside a CMS page are not the user navigating
      // away; blocking them renders the page broken.
      expect(stays('https://youtube.com/embed/x', isMainFrame: false), isTrue);
    });

    test('blocks an unparseable url rather than following it', () {
      expect(stays('::::not a url'), isFalse);
    });
  });
}
