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

  /// Name of the English language option.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the Arabic language option, always shown in Arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Label for the language switcher.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageToggleLabel;

  /// Generic retry button.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Generic loading message.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stateLoading;

  /// Generic empty-state message.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmpty;

  /// Generic, user-friendly error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network/connectivity failure message.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the store. Check your connection and try again.'**
  String get errorNetwork;

  /// Shown when the edge returns a non-JSON/HTML response (WAF/CDN).
  ///
  /// In en, this message translates to:
  /// **'The store is temporarily unavailable. Please try again shortly.'**
  String get errorService;

  /// Title of the Phase 0 diagnostics screen.
  ///
  /// In en, this message translates to:
  /// **'Store health check'**
  String get healthCheckTitle;

  /// Subtitle on the diagnostics screen.
  ///
  /// In en, this message translates to:
  /// **'Live storeConfig for the active store view'**
  String get healthCheckSubtitle;

  /// Label for the store_code value.
  ///
  /// In en, this message translates to:
  /// **'Store code'**
  String get fieldStoreCode;

  /// Label for the locale value.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get fieldLocale;

  /// Label for the currency value.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// Label indicating the default store view.
  ///
  /// In en, this message translates to:
  /// **'Default view'**
  String get fieldDefaultView;

  /// Label for the base URL value.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get fieldBaseUrl;

  /// Label for the media base URL value.
  ///
  /// In en, this message translates to:
  /// **'Media URL'**
  String get fieldMediaUrl;

  /// Heading for the resolved store views list.
  ///
  /// In en, this message translates to:
  /// **'Available store views'**
  String get availableStoresTitle;
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
