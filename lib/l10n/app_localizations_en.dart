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
  String get authSignInTitle => 'Sign In';

  @override
  String get authSignUpTitle => 'Create Account';

  @override
  String get authForgotTitle => 'Reset Password';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get authForgotLink => 'Forgot password?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignUpLink => 'Sign Up';

  @override
  String get authForgotIntro =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get authForgotSent =>
      'If that email is registered, a reset link is on its way.';

  @override
  String get authSignInError =>
      'Couldn\'t sign you in. Please check your details.';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'Use at least 8 characters';

  @override
  String get accountGuestTitle => 'Your ZoonZE account';

  @override
  String get accountGuestBody =>
      'Sign in to track orders, save addresses and check out faster.';

  @override
  String get accountSignOut => 'Sign Out';

  @override
  String get accountOrders => 'My Orders';

  @override
  String get accountAddresses => 'Saved Addresses';

  @override
  String get accountHelp => 'Help & FAQ';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Browse the catalogue and add your favourites.';

  @override
  String get cartContinueShopping => 'Continue shopping';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartDiscount => 'Discount';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String get cartCouponHint => 'Promo code';

  @override
  String get cartApply => 'Apply';

  @override
  String get cartAdded => 'Added to cart';

  @override
  String get cartCouponError => 'That code didn\'t work.';

  @override
  String get wishlistEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistEmptyBody =>
      'Tap the heart on any product to save it here.';

  @override
  String get wishlistSignInPrompt => 'Sign in to save items to your wishlist.';

  @override
  String get wishlistGuestTitle => 'Save your favourites';

  @override
  String get wishlistGuestBody =>
      'Sign in to keep your wishlist across devices.';

  @override
  String get ordersEmpty => 'You have no orders yet.';

  @override
  String get orderStatus => 'Status';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get addressesEmpty => 'No saved addresses yet.';

  @override
  String get addressAdd => 'Add Address';

  @override
  String get addressEdit => 'Edit Address';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get defaultBadge => 'Default';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldStreet => 'Street address';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldPostcode => 'Postcode';

  @override
  String get fieldRegion => 'Area / Emirate';

  @override
  String get fieldCountry => 'Country code';

  @override
  String get addressDefaultShipping => 'Set as default shipping';

  @override
  String get profileTitle => 'Edit Profile';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get profilePasswordSection => 'Change Password';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get reviewsWrite => 'Write a Review';

  @override
  String get reviewRating => 'Your rating';

  @override
  String get reviewNickname => 'Nickname';

  @override
  String get reviewSummary => 'Summary';

  @override
  String get reviewText => 'Your review';

  @override
  String get reviewSubmit => 'Submit Review';

  @override
  String get reviewSubmitted => 'Thank you! Your review is awaiting approval.';

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
