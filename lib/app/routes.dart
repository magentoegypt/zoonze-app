/// Centralised route paths + the primary bottom-nav tabs.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String account = '/account';
  static const String search = '/search';

  static String category(String uid) => '/category/$uid';
  static String product(String urlKey) => '/product/$urlKey';
}

/// Persistent bottom-navigation destinations.
enum AppTab { home, categories, cart, wishlist, account }

extension AppTabRoute on AppTab {
  String get route => switch (this) {
        AppTab.home => AppRoutes.home,
        AppTab.categories => AppRoutes.categories,
        AppTab.cart => AppRoutes.cart,
        AppTab.wishlist => AppRoutes.wishlist,
        AppTab.account => AppRoutes.account,
      };
}
