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
}
