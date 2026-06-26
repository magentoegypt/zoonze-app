// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZoonZE Beauty';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageToggleLabel => 'Language';

  @override
  String get actionRetry => 'Retry';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'We couldn\'t reach the store. Check your connection and try again.';

  @override
  String get errorService =>
      'The store is temporarily unavailable. Please try again shortly.';

  @override
  String get healthCheckTitle => 'Store health check';

  @override
  String get healthCheckSubtitle =>
      'Live storeConfig for the active store view';

  @override
  String get fieldStoreCode => 'Store code';

  @override
  String get fieldLocale => 'Locale';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldDefaultView => 'Default view';

  @override
  String get fieldBaseUrl => 'Base URL';

  @override
  String get fieldMediaUrl => 'Media URL';

  @override
  String get availableStoresTitle => 'Available store views';

  @override
  String get navHome => 'Home';

  @override
  String get navCategories => 'Categories';

  @override
  String get navCart => 'Cart';

  @override
  String get navWishlist => 'Wishlist';

  @override
  String get navAccount => 'Account';

  @override
  String get navSearch => 'Search';

  @override
  String get launchTagline => 'BEAUTY & FRAGRANCE';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeSignIn => 'Sign In';

  @override
  String get welcomeContinueGuest => 'Continue as guest';

  @override
  String get welcomeHeadline => 'Beauty & fragrance, delivered across the UAE';

  @override
  String get welcomeSubtitle => 'Authentic brands, curated for you';

  @override
  String get homeShopByCategory => 'Shop by category';

  @override
  String get homeFeatured => 'Featured';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get filtersLabel => 'Filters';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortPriceLowHigh => 'Price: Low to High';

  @override
  String get sortPriceHighLow => 'Price: High to Low';

  @override
  String get sortNameAz => 'Name: A–Z';

  @override
  String get sortNewest => 'Newest';

  @override
  String get applyLabel => 'Apply';

  @override
  String get clearLabel => 'Clear';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get searchHint => 'Search products';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonBody => 'This section arrives in a later phase.';

  @override
  String get badgeNew => 'NEW';

  @override
  String get badgeBestseller => 'BESTSELLER';

  @override
  String get priceFrom => 'From';

  @override
  String get productAddToCart => 'Add to Cart';

  @override
  String get productOutOfStock => 'Out of stock';

  @override
  String get tabDescription => 'Description';

  @override
  String get tabDetails => 'Details';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get specSku => 'SKU';

  @override
  String get reviewsEmptyTitle => 'No reviews yet';

  @override
  String get reviewsEmptyBody => 'Be the first to review this product.';

  @override
  String reviewsSummary(int rating, int count) {
    return '$rating% rating · $count reviews';
  }

  @override
  String get menuShop => 'Shop';

  @override
  String get menuAccountSection => 'Account';

  @override
  String get menuLogOut => 'Log Out';

  @override
  String get footerShop => 'Shop';

  @override
  String get footerSupport => 'Support';

  @override
  String get footerNewsletterTitle => 'Join our newsletter';

  @override
  String get footerNewsletterHint => 'Email address';

  @override
  String get footerSubscribe => 'Subscribe';

  @override
  String get footerRights => '© ZoonZE Beauty. All rights reserved.';

  @override
  String get footerAbout => 'About';

  @override
  String get footerContact => 'Contact';

  @override
  String get footerShipping => 'Shipping';

  @override
  String get footerReturns => 'Returns';
}
