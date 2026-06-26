// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'زونزي بيوتي';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageToggleLabel => 'اللغة';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get stateLoading => 'جارٍ التحميل…';

  @override
  String get stateEmpty => 'لا يوجد شيء هنا بعد';

  @override
  String get errorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get errorNetwork =>
      'تعذّر الوصول إلى المتجر. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorService => 'المتجر غير متاح مؤقتًا. يرجى المحاولة بعد قليل.';

  @override
  String get healthCheckTitle => 'فحص حالة المتجر';

  @override
  String get healthCheckSubtitle => 'إعدادات المتجر الحيّة لطريقة العرض النشطة';

  @override
  String get fieldStoreCode => 'رمز المتجر';

  @override
  String get fieldLocale => 'اللغة المحلية';

  @override
  String get fieldCurrency => 'العملة';

  @override
  String get fieldDefaultView => 'العرض الافتراضي';

  @override
  String get fieldBaseUrl => 'الرابط الأساسي';

  @override
  String get fieldMediaUrl => 'رابط الوسائط';

  @override
  String get availableStoresTitle => 'طرق عرض المتجر المتاحة';
}
