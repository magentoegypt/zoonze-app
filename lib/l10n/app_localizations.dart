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
  /// **'Zoonze Beauty'**
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

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

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

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and personal data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your Zoonze account, along with your saved addresses and wishlist. Order and invoice records are kept for the period required by UAE law. It cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirmAction;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get deleteAccountFailed;

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
  /// **'Beauty, delivered in hours'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shop authentic fragrance & beauty with free 3-hour delivery across Dubai, Sharjah & Ajman'**
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

  /// No description provided for @homeBestsellers.
  ///
  /// In en, this message translates to:
  /// **'Bestsellers'**
  String get homeBestsellers;

  /// No description provided for @homeExploreBrands.
  ///
  /// In en, this message translates to:
  /// **'Explore Our Brands'**
  String get homeExploreBrands;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get homeSeeMore;

  /// No description provided for @brandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Brands'**
  String get brandsTitle;

  /// No description provided for @brandsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover authentic beauty & fragrance houses'**
  String get brandsSubtitle;

  /// No description provided for @brandsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a brand'**
  String get brandsSearchHint;

  /// No description provided for @brandsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get brandsFilterAll;

  /// No description provided for @brandsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No brands found'**
  String get brandsEmpty;

  /// No description provided for @homeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Free shipping on qualifying orders · delivery within 3 hours'**
  String get homeAnnouncement;

  /// No description provided for @homeTrustOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original 100%'**
  String get homeTrustOriginal;

  /// No description provided for @homeTrustFreeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery over 200 AED'**
  String get homeTrustFreeDelivery;

  /// No description provided for @homeTrustDelivery3h.
  ///
  /// In en, this message translates to:
  /// **'Delivery in 3 Hours in Dubai'**
  String get homeTrustDelivery3h;

  /// No description provided for @homeTrustRestZones.
  ///
  /// In en, this message translates to:
  /// **'Rest Zones in 48 Hours'**
  String get homeTrustRestZones;

  /// No description provided for @homeTrustCustomerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service 10AM Until 10PM'**
  String get homeTrustCustomerService;

  /// No description provided for @homeSpecialOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Special Offer!'**
  String get homeSpecialOfferTitle;

  /// No description provided for @homeSpecialOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Get 25% off on all makeup products'**
  String get homeSpecialOfferBody;

  /// No description provided for @homeSpecialOfferCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Use code:'**
  String get homeSpecialOfferCodeLabel;

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

  /// No description provided for @homeLimitedOfferEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Limited-Time Offer'**
  String get homeLimitedOfferEyebrow;

  /// No description provided for @homeCountdownHours.
  ///
  /// In en, this message translates to:
  /// **'HRS'**
  String get homeCountdownHours;

  /// No description provided for @homeCountdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'MINS'**
  String get homeCountdownMinutes;

  /// No description provided for @homeCountdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'SECS'**
  String get homeCountdownSeconds;

  /// No description provided for @homeDealBadge.
  ///
  /// In en, this message translates to:
  /// **'DEAL'**
  String get homeDealBadge;

  /// No description provided for @homeDealsOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Deals of the Day'**
  String get homeDealsOfTheDay;

  /// No description provided for @homeEditorialSkincareTitle.
  ///
  /// In en, this message translates to:
  /// **'Bare Skin, Better'**
  String get homeEditorialSkincareTitle;

  /// No description provided for @homeEditorialMakeupTitle.
  ///
  /// In en, this message translates to:
  /// **'Every Look, Defined'**
  String get homeEditorialMakeupTitle;

  /// No description provided for @homeExclusiveOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Offers'**
  String get homeExclusiveOffersTitle;

  /// No description provided for @homeExclusiveOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save More Every Order'**
  String get homeExclusiveOffersSubtitle;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @homeTrustReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Shoppers Trust Zoonze'**
  String get homeTrustReviewsTitle;

  /// No description provided for @homeTrustReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loved across the UAE'**
  String get homeTrustReviewsSubtitle;

  /// No description provided for @reviewsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get reviewsScreenTitle;

  /// No description provided for @homeJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'The Zoonze Journal'**
  String get homeJournalTitle;

  /// No description provided for @homeJournalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Beauty notes & guides'**
  String get homeJournalSubtitle;

  /// No description provided for @homeJournalTag.
  ///
  /// In en, this message translates to:
  /// **'BLOGS'**
  String get homeJournalTag;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get homeReadMore;

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

  /// No description provided for @categoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoryCount(int count);

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

  /// No description provided for @filterSortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get filterSortByLabel;

  /// No description provided for @filterPriceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get filterPriceRangeLabel;

  /// No description provided for @filterResetLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterResetLabel;

  /// No description provided for @filterClearAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filterClearAllLabel;

  /// No description provided for @filterApplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApplyLabel;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

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

  /// No description provided for @shareProduct.
  ///
  /// In en, this message translates to:
  /// **'Check out {name} at Zoonze'**
  String shareProduct(String name);

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

  /// No description provided for @sortFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get sortFeatured;

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
  /// **'Newest First'**
  String get sortNewest;

  /// No description provided for @sortComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get sortComingSoon;

  /// No description provided for @filterDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get filterDiscountLabel;

  /// No description provided for @filterRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterRatingLabel;

  /// No description provided for @filterDiscountOption.
  ///
  /// In en, this message translates to:
  /// **'{percent}% or more'**
  String filterDiscountOption(int percent);

  /// No description provided for @filterRatingAndAbove.
  ///
  /// In en, this message translates to:
  /// **'& above'**
  String get filterRatingAndAbove;

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

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Search results for “{query}”'**
  String searchResultsFor(String query);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for products…'**
  String get searchHint;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search for products, brands…'**
  String get searchFieldHint;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// No description provided for @searchTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get searchTrendingTitle;

  /// No description provided for @searchClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearHistory;

  /// No description provided for @searchTrendingCsv.
  ///
  /// In en, this message translates to:
  /// **'Fragrance,Skincare,Makeup,Gift Sets,Bestsellers'**
  String get searchTrendingCsv;

  /// No description provided for @searchForQuery.
  ///
  /// In en, this message translates to:
  /// **'Search “{query}”'**
  String searchForQuery(String query);

  /// No description provided for @searchHintExpanded.
  ///
  /// In en, this message translates to:
  /// **'Search for products, brands…'**
  String get searchHintExpanded;

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
  /// **'Join Zoonze for faster checkout, order tracking & exclusive offers.'**
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
  /// **'Forgot Password?'**
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

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get authBackToSignIn;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailHint;

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

  /// No description provided for @authMethodEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authMethodEmail;

  /// No description provided for @authMethodPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authMethodPhone;

  /// No description provided for @authGetOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get authGetOtp;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get authPhoneHint;

  /// No description provided for @authOtpEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authOtpEnter;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String authOtpSentTo(String phone);

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authResendIn(int seconds);

  /// No description provided for @authVerifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get authVerifyAndSignIn;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authSendWhatsappCode.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp code'**
  String get authSendWhatsappCode;

  /// No description provided for @authSignUpMobileHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll WhatsApp a 6-digit code to confirm this number.'**
  String get authSignUpMobileHelp;

  /// No description provided for @authMobileVerified.
  ///
  /// In en, this message translates to:
  /// **'Mobile number verified'**
  String get authMobileVerified;

  /// No description provided for @authChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get authChangeNumber;

  /// No description provided for @authForgotPhoneIntro.
  ///
  /// In en, this message translates to:
  /// **'No worries! Verify your phone number to reset your password.'**
  String get authForgotPhoneIntro;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with your new password.'**
  String get authResetSuccess;

  /// No description provided for @authOtpRequestError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the code. Please try again.'**
  String get authOtpRequestError;

  /// No description provided for @authOtpVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the code. Please try again.'**
  String get authOtpVerifyError;

  /// No description provided for @fieldMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get fieldMobileNumber;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @validationPhoneUae.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid UAE mobile number'**
  String get validationPhoneUae;

  /// No description provided for @validationPasswordMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get validationPasswordMatch;

  /// No description provided for @checkoutVerifyMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Mobile Number'**
  String get checkoutVerifyMobileTitle;

  /// No description provided for @checkoutVerifyMobileIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your delivery number {phone}'**
  String checkoutVerifyMobileIntro(String phone);

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
  /// **'Your Zoonze account'**
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

  /// No description provided for @accountHeading.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountHeading;

  /// No description provided for @accountAbout.
  ///
  /// In en, this message translates to:
  /// **'About Zoonze'**
  String get accountAbout;

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

  /// No description provided for @accountHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get accountHelpSupport;

  /// No description provided for @accountLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get accountLogOut;

  /// No description provided for @accountMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get accountMember;

  /// No description provided for @accountStatOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get accountStatOrders;

  /// No description provided for @accountStatWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get accountStatWishlist;

  /// No description provided for @accountStatVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get accountStatVouchers;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Zoonze is your destination for authentic beauty and fragrance in the UAE. Since 2008 we\'ve offered 100% genuine perfumes, skincare, makeup and haircare from the world\'s leading luxury brands — with competitive prices, fast delivery and trusted service.'**
  String get aboutBody;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'Zoonze Perfume & Cosmetics Trading LLC'**
  String get aboutCompany;

  /// No description provided for @aboutAddress.
  ///
  /// In en, this message translates to:
  /// **'HHHR Tower, Sheikh Zayed Road, Trade Center First, Dubai, United Arab Emirates'**
  String get aboutAddress;

  /// No description provided for @aboutFollowUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get aboutFollowUs;

  /// No description provided for @aboutWeAccept.
  ///
  /// In en, this message translates to:
  /// **'We Accept'**
  String get aboutWeAccept;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Answers to common questions. Still stuck? Reach our team below.'**
  String get helpIntro;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for help…'**
  String get helpSearchHint;

  /// No description provided for @helpFrequentlyAsked.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked'**
  String get helpFrequentlyAsked;

  /// No description provided for @helpLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get helpLiveChat;

  /// No description provided for @helpCallUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get helpCallUs;

  /// No description provided for @helpEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpEmailLabel;

  /// No description provided for @helpQ1.
  ///
  /// In en, this message translates to:
  /// **'How does Zoonze guarantee 100% authentic products?'**
  String get helpQ1;

  /// No description provided for @helpA1.
  ///
  /// In en, this message translates to:
  /// **'At Zoonze, all perfumes, skincare, makeup, and haircare products are sourced from trusted suppliers and verified to ensure they are 100% authentic.'**
  String get helpA1;

  /// No description provided for @helpQ2.
  ///
  /// In en, this message translates to:
  /// **'Are all perfumes, skincare, haircare and makeup sold by Zoonze original?'**
  String get helpQ2;

  /// No description provided for @helpA2.
  ///
  /// In en, this message translates to:
  /// **'Yes. We only offer genuine products from leading international luxury brands.'**
  String get helpA2;

  /// No description provided for @helpQ3.
  ///
  /// In en, this message translates to:
  /// **'Does Zoonze have a marketplace?'**
  String get helpQ3;

  /// No description provided for @helpA3.
  ///
  /// In en, this message translates to:
  /// **'No. Zoonze doesn\'t operate a marketplace — we never list the same product at different prices or from different vendors. We only offer our own products, guaranteed 100% original.'**
  String get helpA3;

  /// No description provided for @helpQ4.
  ///
  /// In en, this message translates to:
  /// **'What beauty products are available at Zoonze?'**
  String get helpQ4;

  /// No description provided for @helpA4.
  ///
  /// In en, this message translates to:
  /// **'We offer authentic perfumes, skincare products, makeup, and haircare products from top luxury brands worldwide.'**
  String get helpA4;

  /// No description provided for @helpQ5.
  ///
  /// In en, this message translates to:
  /// **'How fast is Zoonze delivery?'**
  String get helpQ5;

  /// No description provided for @helpA5.
  ///
  /// In en, this message translates to:
  /// **'We deliver within 3 hours, and we\'re continuously working toward 2-hour delivery whenever possible.'**
  String get helpA5;

  /// No description provided for @helpQ6.
  ///
  /// In en, this message translates to:
  /// **'Why are Zoonze prices competitive?'**
  String get helpQ6;

  /// No description provided for @helpA6.
  ///
  /// In en, this message translates to:
  /// **'Our goal is to make authentic luxury beauty more accessible through efficient sourcing and operations, allowing us to offer attractive prices.'**
  String get helpA6;

  /// No description provided for @helpQ7.
  ///
  /// In en, this message translates to:
  /// **'Do you offer luxury beauty brands?'**
  String get helpQ7;

  /// No description provided for @helpA7.
  ///
  /// In en, this message translates to:
  /// **'Yes. Zoonze offers a curated collection of premium international brands across fragrances, skincare, makeup, and haircare.'**
  String get helpA7;

  /// No description provided for @helpQ8.
  ///
  /// In en, this message translates to:
  /// **'Can I return or exchange products?'**
  String get helpQ8;

  /// No description provided for @helpA8.
  ///
  /// In en, this message translates to:
  /// **'Yes. We provide an easy return and exchange process in line with our policy.'**
  String get helpA8;

  /// No description provided for @helpQ9.
  ///
  /// In en, this message translates to:
  /// **'Do you provide customer support after purchase?'**
  String get helpQ9;

  /// No description provided for @helpA9.
  ///
  /// In en, this message translates to:
  /// **'Absolutely. From 10 AM until 10 PM, our customer support team is available before and after your purchase to ensure a seamless shopping experience.'**
  String get helpA9;

  /// No description provided for @helpQ10.
  ///
  /// In en, this message translates to:
  /// **'Why should I shop from Zoonze?'**
  String get helpQ10;

  /// No description provided for @helpA10.
  ///
  /// In en, this message translates to:
  /// **'Zoonze combines 100% authentic products, competitive pricing, fast delivery, trusted service, and years of beauty-industry experience since 2008.'**
  String get helpA10;

  /// No description provided for @helpQOrders.
  ///
  /// In en, this message translates to:
  /// **'How can I track my order?'**
  String get helpQOrders;

  /// No description provided for @helpAOrders.
  ///
  /// In en, this message translates to:
  /// **'Open Account → My Orders to see the status of each order.'**
  String get helpAOrders;

  /// No description provided for @helpQPayments.
  ///
  /// In en, this message translates to:
  /// **'What payment methods do you accept?'**
  String get helpQPayments;

  /// No description provided for @helpAPayments.
  ///
  /// In en, this message translates to:
  /// **'Cards via Network International, and Tabby (Pay in 4 / Pay Later) where available at checkout.'**
  String get helpAPayments;

  /// No description provided for @helpQDelivery.
  ///
  /// In en, this message translates to:
  /// **'How fast is delivery?'**
  String get helpQDelivery;

  /// No description provided for @helpADelivery.
  ///
  /// In en, this message translates to:
  /// **'Free 3-hour delivery in Dubai, Sharjah & Ajman on orders over AED 150. The rest of the UAE is delivered within 24 hours.'**
  String get helpADelivery;

  /// No description provided for @helpQReturns.
  ///
  /// In en, this message translates to:
  /// **'How do I return or exchange a product?'**
  String get helpQReturns;

  /// No description provided for @helpAReturns.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team within 14 days of delivery to arrange a return or exchange.'**
  String get helpAReturns;

  /// No description provided for @helpQAuthentic.
  ///
  /// In en, this message translates to:
  /// **'Are all products 100% authentic?'**
  String get helpQAuthentic;

  /// No description provided for @helpAAuthentic.
  ///
  /// In en, this message translates to:
  /// **'Yes. Every product is sourced from authorised distributors and is guaranteed 100% authentic.'**
  String get helpAAuthentic;

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

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Order updates, offers and price drops will show up here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notifJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notifJustNow;

  /// No description provided for @notifMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String notifMinutesAgo(int count);

  /// No description provided for @notifHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String notifHoursAgo(int count);

  /// No description provided for @notifYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifYesterday;

  /// No description provided for @notifDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String notifDaysAgo(int count);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartHeading.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get cartHeading;

  /// No description provided for @cartItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String cartItemCount(int count);

  /// No description provided for @cartSecureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed To Checkout'**
  String get cartSecureCheckout;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Looks like you haven\'t added anything yet. Explore our bestsellers and find your signature scent.'**
  String get cartEmptyBody;

  /// No description provided for @cartContinueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get cartContinueShopping;

  /// No description provided for @cartStartShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get cartStartShopping;

  /// No description provided for @cartOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get cartOrderSummary;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotal;

  /// No description provided for @cartSubtotalCount.
  ///
  /// In en, this message translates to:
  /// **'Subtotal ({count, plural, =1{1 item} other{{count} items}})'**
  String cartSubtotalCount(int count);

  /// No description provided for @cartPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo ({code})'**
  String cartPromoCode(String code);

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get cartDiscount;

  /// No description provided for @cartDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery (3-hour)'**
  String get cartDelivery;

  /// No description provided for @cartDeliveryFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get cartDeliveryFree;

  /// No description provided for @cartDeliveryCalculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated at checkout'**
  String get cartDeliveryCalculated;

  /// No description provided for @cartFreeDeliveryUnlocked.
  ///
  /// In en, this message translates to:
  /// **'You\'ve unlocked FREE 3-hour delivery!'**
  String get cartFreeDeliveryUnlocked;

  /// No description provided for @cartFreeDeliveryRemaining.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more for FREE 3-hour delivery'**
  String cartFreeDeliveryRemaining(String amount);

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
  /// **'Gift or promo code'**
  String get cartCouponHint;

  /// No description provided for @cartApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cartApply;

  /// No description provided for @cartCouponApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied'**
  String cartCouponApplied(String code);

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

  /// No description provided for @wishlistHeading.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get wishlistHeading;

  /// No description provided for @wishlistSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved item} other{{count} saved items}}'**
  String wishlistSavedCount(int count);

  /// No description provided for @wishlistAddAll.
  ///
  /// In en, this message translates to:
  /// **'Add all to Bag'**
  String get wishlistAddAll;

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

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterToReceive.
  ///
  /// In en, this message translates to:
  /// **'To Receive'**
  String get ordersFilterToReceive;

  /// No description provided for @ordersFilterDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ordersFilterDelivered;

  /// No description provided for @ordersFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ordersFilterCancelled;

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
  /// **'View Details'**
  String get orderViewDetails;

  /// No description provided for @orderMoreItems.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String orderMoreItems(int count);

  /// No description provided for @orderPaymentSection.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get orderPaymentSection;

  /// No description provided for @orderTimelineSection.
  ///
  /// In en, this message translates to:
  /// **'Order Timeline'**
  String get orderTimelineSection;

  /// No description provided for @orderBillingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get orderBillingAddress;

  /// No description provided for @orderItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String orderItemCount(int count);

  /// No description provided for @orderTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotalLabel;

  /// No description provided for @orderTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get orderTrack;

  /// No description provided for @orderReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get orderReorder;

  /// No description provided for @orderReorderAdded.
  ///
  /// In en, this message translates to:
  /// **'Items added to your cart'**
  String get orderReorderAdded;

  /// No description provided for @orderReorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reorder these items. Please try again.'**
  String get orderReorderFailed;

  /// No description provided for @trackOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrderTitle;

  /// No description provided for @orderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatusTitle;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @orderStageConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderStageConfirmed;

  /// No description provided for @orderStagePacked.
  ///
  /// In en, this message translates to:
  /// **'Packed & Ready'**
  String get orderStagePacked;

  /// No description provided for @orderStageOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get orderStageOutForDelivery;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get orderDeliveryAddress;

  /// No description provided for @orderItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String orderItemsCount(int count);

  /// No description provided for @orderQty.
  ///
  /// In en, this message translates to:
  /// **'Qty {count}'**
  String orderQty(int count);

  /// No description provided for @orderNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help with this order?'**
  String get orderNeedHelp;

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
  /// **'Phone Number'**
  String get fieldPhone;

  /// No description provided for @fieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
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

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fieldFullName;

  /// No description provided for @fieldEmirate.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get fieldEmirate;

  /// No description provided for @fieldCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get fieldCountryLabel;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get fieldArea;

  /// No description provided for @fieldApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment / Floor (optional)'**
  String get fieldApartment;

  /// No description provided for @checkoutUseNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Use a new address'**
  String get checkoutUseNewAddress;

  /// No description provided for @addressDefaultShipping.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get addressDefaultShipping;

  /// No description provided for @addressSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get addressSaveAs;

  /// No description provided for @addressDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get addressDefaultBadge;

  /// No description provided for @addressAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addressAddNew;

  /// No description provided for @addressSave.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get addressSave;

  /// No description provided for @addressHintName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hassan Ahmed'**
  String get addressHintName;

  /// No description provided for @addressHintPhone.
  ///
  /// In en, this message translates to:
  /// **'+971 50 000 0000'**
  String get addressHintPhone;

  /// No description provided for @addressHintArea.
  ///
  /// In en, this message translates to:
  /// **'Jumeirah 1'**
  String get addressHintArea;

  /// No description provided for @addressHintStreet.
  ///
  /// In en, this message translates to:
  /// **'Street 9'**
  String get addressHintStreet;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @checkoutEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'Order updates will be sent to this email.'**
  String get checkoutEmailHelp;

  /// No description provided for @checkoutDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get checkoutDeliveryAddress;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

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

  /// No description provided for @profilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInfo;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get profileChangePhoto;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile photo upload isn\'t available yet.'**
  String get profilePhotoUnavailable;

  /// No description provided for @profilePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get profilePushNotifications;

  /// No description provided for @profileEmailOffers.
  ///
  /// In en, this message translates to:
  /// **'Email Offers'**
  String get profileEmailOffers;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileMobileChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileMobileChange;

  /// No description provided for @profileMobileAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileMobileAdd;

  /// No description provided for @profileMobileNotSet.
  ///
  /// In en, this message translates to:
  /// **'No mobile number added'**
  String get profileMobileNotSet;

  /// No description provided for @profileMobileVerifyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Verify & Update'**
  String get profileMobileVerifyUpdate;

  /// No description provided for @profileMobileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated'**
  String get profileMobileUpdated;

  /// No description provided for @profileMobileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your mobile number. Please try again.'**
  String get profileMobileUpdateError;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

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
  /// **'Payment Method'**
  String get checkoutPayment;

  /// No description provided for @checkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get checkoutSummary;

  /// No description provided for @checkoutDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get checkoutDeliveryFee;

  /// No description provided for @checkoutPaymentSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Online payments are processed securely. Cash on delivery available across the UAE.'**
  String get checkoutPaymentSecurityNote;

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

  /// No description provided for @tabbyInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay in 4 with Tabby'**
  String get tabbyInfoTitle;

  /// No description provided for @tabbyInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Split your purchase into 4 equal, interest-free payments. No fees when you pay on time.'**
  String get tabbyInfoBody;

  /// No description provided for @tabbyInfoGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tabbyInfoGotIt;

  /// No description provided for @paymentSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tabby is unavailable for this order. Please choose another payment method.'**
  String get paymentSessionUnavailable;

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
  /// **'Order Placed!'**
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

  /// No description provided for @orderSuccessThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your order is confirmed and on its way.'**
  String get orderSuccessThanks;

  /// No description provided for @orderSuccessThanksNamed.
  ///
  /// In en, this message translates to:
  /// **'Thank you, {name}! Your order is confirmed and on its way.'**
  String orderSuccessThanksNamed(String name);

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumberLabel;

  /// No description provided for @orderNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Order number copied'**
  String get orderNumberCopied;

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

  /// No description provided for @tabKeyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get tabKeyFeatures;

  /// No description provided for @tabMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'More Information'**
  String get tabMoreInformation;

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

  /// No description provided for @attrBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get attrBrand;

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

  /// No description provided for @pdpQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get pdpQuantityLabel;

  /// No description provided for @pdpYouMayAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You may also like'**
  String get pdpYouMayAlsoLike;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @pdpRatingReviews.
  ///
  /// In en, this message translates to:
  /// **'{rating} · {count} reviews'**
  String pdpRatingReviews(String rating, int count);

  /// No description provided for @pdpTrustAuthenticValue.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get pdpTrustAuthenticValue;

  /// No description provided for @pdpTrustAuthenticLabel.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get pdpTrustAuthenticLabel;

  /// No description provided for @pdpTrustFreeValue.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get pdpTrustFreeValue;

  /// No description provided for @pdpTrustFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get pdpTrustFreeLabel;

  /// No description provided for @pdpTrustFreeOver.
  ///
  /// In en, this message translates to:
  /// **'Delivery over AED {amount}'**
  String pdpTrustFreeOver(int amount);

  /// No description provided for @pdpTrustDeliveryValue.
  ///
  /// In en, this message translates to:
  /// **'3 Hours'**
  String get pdpTrustDeliveryValue;

  /// No description provided for @pdpTrustDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'in Dubai · 48h elsewhere'**
  String get pdpTrustDeliveryLabel;

  /// No description provided for @menuShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get menuShop;

  /// No description provided for @menuViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get menuViewAll;

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

  /// No description provided for @drawerVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get drawerVouchers;

  /// No description provided for @footerShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get footerShop;

  /// No description provided for @footerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer Care'**
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
  /// **'© 2026 Zoonze · All rights reserved.'**
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
  /// **'Contact Us'**
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
  /// **'Terms & Conditions'**
  String get footerTerms;

  /// No description provided for @footerShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping & Delivery'**
  String get footerShipping;

  /// No description provided for @footerReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns & Exchanges'**
  String get footerReturns;

  /// No description provided for @webviewOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get webviewOpenInBrowser;
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
