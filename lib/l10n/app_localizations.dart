import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application title shown in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'ZoonZE Beauty'**
  String get appTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageToggleLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @themeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get themeWhite;

  /// No description provided for @themeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get themeBlack;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get actionLinkCopied;

  /// No description provided for @stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmpty;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the store. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorService.
  ///
  /// In en, this message translates to:
  /// **'The store is temporarily unavailable. Please try again shortly.'**
  String get errorService;

  /// No description provided for @healthCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Store health check'**
  String get healthCheckTitle;

  /// No description provided for @healthCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live storeConfig for the active store view'**
  String get healthCheckSubtitle;

  /// No description provided for @settingsConnectionTest.
  ///
  /// In en, this message translates to:
  /// **'Connection test'**
  String get settingsConnectionTest;

  /// No description provided for @settingsConnectionTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the live connection to the store'**
  String get settingsConnectionTestSubtitle;

  /// No description provided for @fieldStoreCode.
  ///
  /// In en, this message translates to:
  /// **'Store code'**
  String get fieldStoreCode;

  /// No description provided for @fieldLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get fieldLocale;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldDefaultView.
  ///
  /// In en, this message translates to:
  /// **'Default view'**
  String get fieldDefaultView;

  /// No description provided for @fieldBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get fieldBaseUrl;

  /// No description provided for @fieldMediaUrl.
  ///
  /// In en, this message translates to:
  /// **'Media URL'**
  String get fieldMediaUrl;

  /// No description provided for @availableStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Available store views'**
  String get availableStoresTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// No description provided for @navWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get navWishlist;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @launchTagline.
  ///
  /// In en, this message translates to:
  /// **'BEAUTY & FRAGRANCE'**
  String get launchTagline;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get welcomeSignIn;

  /// No description provided for @welcomeContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get welcomeContinueGuest;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Beauty & fragrance, delivered across the UAE'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentic brands, curated for you'**
  String get welcomeSubtitle;

  /// No description provided for @homeShopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by category'**
  String get homeShopByCategory;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get homeFeatured;

  /// No description provided for @homeNewArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get homeNewArrivals;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Free shipping on orders over AED 150'**
  String get homeAnnouncement;

  /// No description provided for @homeTrustOriginalTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Original'**
  String get homeTrustOriginalTitle;

  /// No description provided for @homeTrustOriginalBody.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed authentic'**
  String get homeTrustOriginalBody;

  /// No description provided for @homeTrustDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get homeTrustDeliveryTitle;

  /// No description provided for @homeTrustDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'On orders over AED 150'**
  String get homeTrustDeliveryBody;

  /// No description provided for @homeTrustServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get homeTrustServiceTitle;

  /// No description provided for @homeTrustServiceBody.
  ///
  /// In en, this message translates to:
  /// **'10 AM – 10 PM'**
  String get homeTrustServiceBody;

  /// No description provided for @homeHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEW COLLECTION'**
  String get homeHeroEyebrow;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Beauty, your way'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentic brands, curated for the UAE'**
  String get homeHeroSubtitle;

  /// No description provided for @homeHeroCta.
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get homeHeroCta;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop by what you love'**
  String get categoriesSubtitle;

  /// No description provided for @categoryProductCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String categoryProductCount(int count);

  /// No description provided for @filtersLabel.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersLabel;

  /// No description provided for @filterPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get filterPriceLabel;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortPriceLowHigh;

  /// No description provided for @sortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortPriceHighLow;

  /// No description provided for @sortNameAz.
  ///
  /// In en, this message translates to:
  /// **'Name: A–Z'**
  String get sortNameAz;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @applyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchHint;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This section arrives in a later phase.'**
  String get comingSoonBody;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInTitle;

  /// No description provided for @authSignInWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInWelcome;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue shopping'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join ZoonZE for faster checkout, order tracking & exclusive offers.'**
  String get authSignUpSubtitle;

  /// No description provided for @authAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service & Privacy Policy'**
  String get authAgreeTerms;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authForgotSubmit;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// No description provided for @authForgotLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotLink;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authSignUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUpLink;

  /// No description provided for @authForgotIntro.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email and we\'ll send you a link to reset your password.'**
  String get authForgotIntro;

  /// No description provided for @authForgotSent.
  ///
  /// In en, this message translates to:
  /// **'If that email is registered, a reset link is on its way.'**
  String get authForgotSent;

  /// No description provided for @authHaveResetCode.
  ///
  /// In en, this message translates to:
  /// **'I have a reset code'**
  String get authHaveResetCode;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a New Password'**
  String get authResetTitle;

  /// No description provided for @authResetIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your reset email and choose a new password.'**
  String get authResetIntro;

  /// No description provided for @authResetError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reset your password. Check the code and try again.'**
  String get authResetError;

  /// No description provided for @fieldResetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get fieldResetCode;

  /// No description provided for @authSignInError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in. Please check your details.'**
  String get authSignInError;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmail;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get validationPassword;

  /// No description provided for @accountGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your ZoonZE account'**
  String get accountGuestTitle;

  /// No description provided for @accountGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track orders, save addresses and check out faster.'**
  String get accountGuestBody;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOut;

  /// No description provided for @accountOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get accountOrders;

  /// No description provided for @accountAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get accountAddresses;

  /// No description provided for @accountHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get accountHelp;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Answers to common questions. Still stuck? Reach our team below.'**
  String get helpIntro;

  /// No description provided for @helpQOrders.
  ///
  /// In en, this message translates to:
  /// **'How do I track my order?'**
  String get helpQOrders;

  /// No description provided for @helpAOrders.
  ///
  /// In en, this message translates to:
  /// **'Open Account → My Orders to see the status of each order.'**
  String get helpAOrders;

  /// No description provided for @helpQPayments.
  ///
  /// In en, this message translates to:
  /// **'Which payment methods can I use?'**
  String get helpQPayments;

  /// No description provided for @helpAPayments.
  ///
  /// In en, this message translates to:
  /// **'Cards via Network International, and Tabby (Pay in 4 / Pay Later) where available at checkout.'**
  String get helpAPayments;

  /// No description provided for @helpQDelivery.
  ///
  /// In en, this message translates to:
  /// **'Where do you deliver?'**
  String get helpQDelivery;

  /// No description provided for @helpADelivery.
  ///
  /// In en, this message translates to:
  /// **'We deliver across the United Arab Emirates.'**
  String get helpADelivery;

  /// No description provided for @helpQReturns.
  ///
  /// In en, this message translates to:
  /// **'How do I return an item?'**
  String get helpQReturns;

  /// No description provided for @helpAReturns.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team within 14 days of delivery to arrange a return.'**
  String get helpAReturns;

  /// No description provided for @helpQLanguage.
  ///
  /// In en, this message translates to:
  /// **'How do I change the language?'**
  String get helpQLanguage;

  /// No description provided for @helpALanguage.
  ///
  /// In en, this message translates to:
  /// **'Use the EN / العربية toggle in the menu or in Settings.'**
  String get helpALanguage;

  /// No description provided for @helpContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get helpContactTitle;

  /// No description provided for @helpEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get helpEmailAction;

  /// No description provided for @helpWebsiteAction.
  ///
  /// In en, this message translates to:
  /// **'Visit zoonze.com'**
  String get helpWebsiteAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions & offers'**
  String get notificationsPromoTitle;

  /// No description provided for @notificationsPromoBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified about sales, new arrivals and exclusive offers.'**
  String get notificationsPromoBody;

  /// No description provided for @notificationsOrdersNote.
  ///
  /// In en, this message translates to:
  /// **'Order updates are always sent for your purchases.'**
  String get notificationsOrdersNote;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Browse the catalogue and add your favourites.'**
  String get cartEmptyBody;

  /// No description provided for @cartContinueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get cartContinueShopping;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotal;

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get cartDiscount;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckout;

  /// No description provided for @cartCouponHint.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get cartCouponHint;

  /// No description provided for @cartApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cartApply;

  /// No description provided for @cartAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get cartAdded;

  /// No description provided for @cartCouponError.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work.'**
  String get cartCouponError;

  /// No description provided for @wishlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmptyTitle;

  /// No description provided for @wishlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any product to save it here.'**
  String get wishlistEmptyBody;

  /// No description provided for @wishlistSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save items to your wishlist.'**
  String get wishlistSignInPrompt;

  /// No description provided for @wishlistGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your favourites'**
  String get wishlistGuestTitle;

  /// No description provided for @wishlistGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your wishlist across devices.'**
  String get wishlistGuestBody;

  /// No description provided for @ordersEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no orders yet.'**
  String get ordersEmpty;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @orderItemsSection.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderItemsSection;

  /// No description provided for @orderTrackingSection.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get orderTrackingSection;

  /// No description provided for @orderShippingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get orderShippingLabel;

  /// No description provided for @orderNoTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking details appear here once your order ships.'**
  String get orderNoTracking;

  /// No description provided for @orderTrackingCopied.
  ///
  /// In en, this message translates to:
  /// **'Tracking number copied'**
  String get orderTrackingCopied;

  /// No description provided for @orderViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get orderViewDetails;

  /// No description provided for @addressesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet.'**
  String get addressesEmpty;

  /// No description provided for @addressAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addressAdd;

  /// No description provided for @addressEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get addressEdit;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBadge;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhone;

  /// No description provided for @fieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get fieldStreet;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @fieldPostcode.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get fieldPostcode;

  /// No description provided for @fieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Area / Emirate'**
  String get fieldRegion;

  /// No description provided for @fieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get fieldCountry;

  /// No description provided for @addressDefaultShipping.
  ///
  /// In en, this message translates to:
  /// **'Set as default shipping'**
  String get addressDefaultShipping;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileTitle;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @profilePasswordSection.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profilePasswordSection;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @reviewsWrite.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get reviewsWrite;

  /// No description provided for @reviewRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get reviewRating;

  /// No description provided for @reviewNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get reviewNickname;

  /// No description provided for @reviewSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reviewSummary;

  /// No description provided for @reviewText.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get reviewText;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get reviewSubmit;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your review is awaiting approval.'**
  String get reviewSubmitted;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get checkoutContact;

  /// No description provided for @checkoutShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get checkoutShippingAddress;

  /// No description provided for @checkoutShippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get checkoutShippingMethod;

  /// No description provided for @checkoutPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutPayment;

  /// No description provided for @checkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get checkoutSummary;

  /// No description provided for @checkoutContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get checkoutContinue;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutPayIn4.
  ///
  /// In en, this message translates to:
  /// **'or 4 interest-free payments'**
  String get checkoutPayIn4;

  /// No description provided for @checkoutPayLater.
  ///
  /// In en, this message translates to:
  /// **'Pay later, interest-free'**
  String get checkoutPayLater;

  /// No description provided for @checkoutCardInstalments.
  ///
  /// In en, this message translates to:
  /// **'Pay by card in instalments'**
  String get checkoutCardInstalments;

  /// No description provided for @checkoutFreeOrder.
  ///
  /// In en, this message translates to:
  /// **'No payment needed — your order total is free'**
  String get checkoutFreeOrder;

  /// No description provided for @promoTabbyPayIn4.
  ///
  /// In en, this message translates to:
  /// **'or {count} interest-free payments of {amount}'**
  String promoTabbyPayIn4(int count, String amount);

  /// No description provided for @promoTabbyPayLater.
  ///
  /// In en, this message translates to:
  /// **'or pay later, interest-free'**
  String get promoTabbyPayLater;

  /// No description provided for @promoTabbyCardInstalments.
  ///
  /// In en, this message translates to:
  /// **'or pay by card in instalments'**
  String get promoTabbyCardInstalments;

  /// No description provided for @paymentSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tabby is unavailable for this order. Please choose another payment method.'**
  String get paymentSessionUnavailable;

  /// No description provided for @fieldCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get fieldCountryLabel;

  /// No description provided for @countryUae.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get countryUae;

  /// No description provided for @paymentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Payment was declined. Please choose another payment method.'**
  String get paymentDeclined;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment couldn\'t be completed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @paymentExpired.
  ///
  /// In en, this message translates to:
  /// **'Your payment session expired. Please try again.'**
  String get paymentExpired;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Your payment is still processing. Please try again in a moment.'**
  String get paymentProcessing;

  /// No description provided for @completePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get completePaymentTitle;

  /// No description provided for @completePaymentBody.
  ///
  /// In en, this message translates to:
  /// **'Order {number} is placed and awaiting payment. Choose how you\'d like to pay.'**
  String completePaymentBody(String number);

  /// No description provided for @completePaymentPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get completePaymentPayNow;

  /// No description provided for @completePaymentPayLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll pay later'**
  String get completePaymentPayLater;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderSuccessTitle;

  /// No description provided for @orderPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Order received'**
  String get orderPendingTitle;

  /// No description provided for @orderSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your order number is {number}.'**
  String orderSuccessBody(String number);

  /// No description provided for @paymentRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get paymentRedirectTitle;

  /// No description provided for @paymentRedirectPending.
  ///
  /// In en, this message translates to:
  /// **'Your order is placed and awaiting payment confirmation. We\'ll notify you once your payment is completed.'**
  String get paymentRedirectPending;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get badgeNew;

  /// No description provided for @badgeBestseller.
  ///
  /// In en, this message translates to:
  /// **'BESTSELLER'**
  String get badgeBestseller;

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get priceFrom;

  /// No description provided for @productAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productAddToCart;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productOutOfStock;

  /// No description provided for @tabDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tabDescription;

  /// No description provided for @tabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// No description provided for @tabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tabReviews;

  /// No description provided for @specSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get specSku;

  /// No description provided for @reviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsEmptyTitle;

  /// No description provided for @reviewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review this product.'**
  String get reviewsEmptyBody;

  /// No description provided for @reviewsSummary.
  ///
  /// In en, this message translates to:
  /// **'{rating}% rating · {count} reviews'**
  String reviewsSummary(int rating, int count);

  /// No description provided for @menuShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get menuShop;

  /// No description provided for @menuAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menuAccountSection;

  /// No description provided for @menuLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get menuLogOut;

  /// No description provided for @footerShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get footerShop;

  /// No description provided for @footerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get footerSupport;

  /// No description provided for @footerNewsletterTitle.
  ///
  /// In en, this message translates to:
  /// **'Newsletter'**
  String get footerNewsletterTitle;

  /// No description provided for @footerNewsletterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to get special offers and updates.'**
  String get footerNewsletterSubtitle;

  /// No description provided for @footerNewsletterHint.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get footerNewsletterHint;

  /// No description provided for @footerSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get footerSubscribe;

  /// No description provided for @footerSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We\'ll keep you posted.'**
  String get footerSubscribed;

  /// No description provided for @footerRights.
  ///
  /// In en, this message translates to:
  /// **'© 2026 ZoonZE Beauty · All rights reserved.'**
  String get footerRights;

  /// No description provided for @footerTagline.
  ///
  /// In en, this message translates to:
  /// **'Your destination for authentic beauty & fragrance in the UAE.'**
  String get footerTagline;

  /// No description provided for @footerAboutHeading.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get footerAboutHeading;

  /// No description provided for @footerAbout.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get footerAbout;

  /// No description provided for @footerContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get footerContact;

  /// No description provided for @footerStoreLocator.
  ///
  /// In en, this message translates to:
  /// **'Store Locator'**
  String get footerStoreLocator;

  /// No description provided for @footerTrackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get footerTrackOrder;

  /// No description provided for @footerShippingReturns.
  ///
  /// In en, this message translates to:
  /// **'Shipping & Returns'**
  String get footerShippingReturns;

  /// No description provided for @footerFaqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get footerFaqs;

  /// No description provided for @footerPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get footerPrivacy;

  /// No description provided for @footerTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get footerTerms;

  /// No description provided for @footerShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get footerShipping;

  /// No description provided for @footerReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get footerReturns;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
