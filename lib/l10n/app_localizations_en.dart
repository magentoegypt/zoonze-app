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
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeWhite => 'White';

  @override
  String get themeBlack => 'Black';

  @override
  String get themeSystem => 'System';

  @override
  String get versionLabel => 'Version';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionLinkCopied => 'Link copied to clipboard';

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
  String get settingsConnectionTest => 'Connection test';

  @override
  String get settingsConnectionTestSubtitle =>
      'Check the live connection to the store';

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
  String get homeNewArrivals => 'New Arrivals';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeAnnouncement => 'Free shipping on orders over AED 150';

  @override
  String get homeTrustOriginalTitle => '100% Original';

  @override
  String get homeTrustOriginalBody => 'Guaranteed authentic';

  @override
  String get homeTrustDeliveryTitle => 'Free Delivery';

  @override
  String get homeTrustDeliveryBody => 'On orders over AED 150';

  @override
  String get homeTrustServiceTitle => 'Customer Service';

  @override
  String get homeTrustServiceBody => '10 AM – 10 PM';

  @override
  String get homeHeroEyebrow => 'NEW COLLECTION';

  @override
  String get homeHeroTitle => 'Beauty, your way';

  @override
  String get homeHeroSubtitle => 'Authentic brands, curated for the UAE';

  @override
  String get homeHeroCta => 'Shop Now';

  @override
  String get categoriesSubtitle => 'Shop by what you love';

  @override
  String categoryProductCount(int count) {
    return '$count products';
  }

  @override
  String get filtersLabel => 'Filters';

  @override
  String get filterPriceLabel => 'Price';

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
  String get authSignInWelcome => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to continue shopping';

  @override
  String get authSignUpTitle => 'Create Account';

  @override
  String get authSignUpSubtitle =>
      'Join ZoonZE for faster checkout, order tracking & exclusive offers.';

  @override
  String get authAgreeTerms =>
      'I agree to the Terms of Service & Privacy Policy';

  @override
  String get authForgotTitle => 'Forgot Password?';

  @override
  String get authForgotSubmit => 'Send Reset Link';

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
      'No worries! Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get authForgotSent =>
      'If that email is registered, a reset link is on its way.';

  @override
  String get authHaveResetCode => 'I have a reset code';

  @override
  String get authResetTitle => 'Set a New Password';

  @override
  String get authResetIntro =>
      'Enter the code from your reset email and choose a new password.';

  @override
  String get authResetError =>
      'Couldn\'t reset your password. Check the code and try again.';

  @override
  String get fieldResetCode => 'Reset code';

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
  String get accountHeading => 'My Account';

  @override
  String get accountAbout => 'About ZoonZE';

  @override
  String get accountOrders => 'My Orders';

  @override
  String get accountAddresses => 'Saved Addresses';

  @override
  String get accountHelp => 'Help & FAQ';

  @override
  String get helpIntro =>
      'Answers to common questions. Still stuck? Reach our team below.';

  @override
  String get helpQOrders => 'How do I track my order?';

  @override
  String get helpAOrders =>
      'Open Account → My Orders to see the status of each order.';

  @override
  String get helpQPayments => 'Which payment methods can I use?';

  @override
  String get helpAPayments =>
      'Cards via Network International, and Tabby (Pay in 4 / Pay Later) where available at checkout.';

  @override
  String get helpQDelivery => 'Where do you deliver?';

  @override
  String get helpADelivery => 'We deliver across the United Arab Emirates.';

  @override
  String get helpQReturns => 'How do I return an item?';

  @override
  String get helpAReturns =>
      'Contact our support team within 14 days of delivery to arrange a return.';

  @override
  String get helpQLanguage => 'How do I change the language?';

  @override
  String get helpALanguage =>
      'Use the EN / العربية toggle in the menu or in Settings.';

  @override
  String get helpContactTitle => 'Still need help?';

  @override
  String get helpEmailAction => 'Email support';

  @override
  String get helpWebsiteAction => 'Visit zoonze.com';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsPromoTitle => 'Promotions & offers';

  @override
  String get notificationsPromoBody =>
      'Get notified about sales, new arrivals and exclusive offers.';

  @override
  String get notificationsOrdersNote =>
      'Order updates are always sent for your purchases.';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartHeading => 'My Cart';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get cartSecureCheckout => 'Secure Checkout';

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
  String get orderDetailsTitle => 'Order Details';

  @override
  String get orderItemsSection => 'Items';

  @override
  String get orderTrackingSection => 'Tracking';

  @override
  String get orderShippingLabel => 'Shipping';

  @override
  String get orderNoTracking =>
      'Tracking details appear here once your order ships.';

  @override
  String get orderTrackingCopied => 'Tracking number copied';

  @override
  String get orderViewDetails => 'View details';

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
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutContact => 'Contact';

  @override
  String get checkoutShippingAddress => 'Shipping Address';

  @override
  String get checkoutShippingMethod => 'Shipping Method';

  @override
  String get checkoutPayment => 'Payment';

  @override
  String get checkoutSummary => 'Order Summary';

  @override
  String get checkoutContinue => 'Continue';

  @override
  String get checkoutPlaceOrder => 'Place Order';

  @override
  String get checkoutPayIn4 => 'or 4 interest-free payments';

  @override
  String get checkoutPayLater => 'Pay later, interest-free';

  @override
  String get checkoutCardInstalments => 'Pay by card in instalments';

  @override
  String get checkoutFreeOrder =>
      'No payment needed — your order total is free';

  @override
  String promoTabbyPayIn4(int count, String amount) {
    return 'or $count interest-free payments of $amount';
  }

  @override
  String get promoTabbyPayLater => 'or pay later, interest-free';

  @override
  String get promoTabbyCardInstalments => 'or pay by card in instalments';

  @override
  String get paymentSessionUnavailable =>
      'Tabby is unavailable for this order. Please choose another payment method.';

  @override
  String get fieldCountryLabel => 'Country';

  @override
  String get countryUae => 'United Arab Emirates';

  @override
  String get paymentDeclined =>
      'Payment was declined. Please choose another payment method.';

  @override
  String get paymentFailed =>
      'Payment couldn\'t be completed. Please try again.';

  @override
  String get paymentExpired =>
      'Your payment session expired. Please try again.';

  @override
  String get paymentProcessing =>
      'Your payment is still processing. Please try again in a moment.';

  @override
  String get completePaymentTitle => 'Complete payment';

  @override
  String completePaymentBody(String number) {
    return 'Order $number is placed and awaiting payment. Choose how you\'d like to pay.';
  }

  @override
  String get completePaymentPayNow => 'Pay now';

  @override
  String get completePaymentPayLater => 'I\'ll pay later';

  @override
  String get orderSuccessTitle => 'Order placed!';

  @override
  String get orderPendingTitle => 'Order received';

  @override
  String orderSuccessBody(String number) {
    return 'Thank you. Your order number is $number.';
  }

  @override
  String get orderNumberLabel => 'Order Number';

  @override
  String get orderNumberCopied => 'Order number copied';

  @override
  String get paymentRedirectTitle => 'Complete payment';

  @override
  String get paymentRedirectPending =>
      'Your order is placed and awaiting payment confirmation. We\'ll notify you once your payment is completed.';

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
  String get footerNewsletterTitle => 'Newsletter';

  @override
  String get footerNewsletterSubtitle =>
      'Subscribe to get special offers and updates.';

  @override
  String get footerNewsletterHint => 'Your email';

  @override
  String get footerSubscribe => 'Subscribe';

  @override
  String get footerSubscribed => 'Thanks! We\'ll keep you posted.';

  @override
  String get footerRights => '© 2026 ZoonZE Beauty · All rights reserved.';

  @override
  String get footerTagline =>
      'Your destination for authentic beauty & fragrance in the UAE.';

  @override
  String get footerAboutHeading => 'About Us';

  @override
  String get footerAbout => 'About Us';

  @override
  String get footerContact => 'Contact';

  @override
  String get footerStoreLocator => 'Store Locator';

  @override
  String get footerTrackOrder => 'Track Order';

  @override
  String get footerShippingReturns => 'Shipping & Returns';

  @override
  String get footerFaqs => 'FAQs';

  @override
  String get footerPrivacy => 'Privacy Policy';

  @override
  String get footerTerms => 'Terms of Service';

  @override
  String get footerShipping => 'Shipping';

  @override
  String get footerReturns => 'Returns';
}
