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

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCategories => 'الفئات';

  @override
  String get navCart => 'السلة';

  @override
  String get navWishlist => 'المفضلة';

  @override
  String get navAccount => 'حسابي';

  @override
  String get navSearch => 'بحث';

  @override
  String get launchTagline => 'الجمال والعطور';

  @override
  String get welcomeGetStarted => 'ابدأ الآن';

  @override
  String get welcomeSignIn => 'تسجيل الدخول';

  @override
  String get welcomeContinueGuest => 'المتابعة كزائر';

  @override
  String get welcomeHeadline => 'الجمال والعطور، توصيل في جميع أنحاء الإمارات';

  @override
  String get welcomeSubtitle => 'علامات أصلية، مختارة لك';

  @override
  String get homeShopByCategory => 'تسوّق حسب الفئة';

  @override
  String get homeFeatured => 'مميّزة';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get filtersLabel => 'تصفية';

  @override
  String get sortLabel => 'ترتيب';

  @override
  String get sortRelevance => 'الصلة';

  @override
  String get sortPriceLowHigh => 'السعر: من الأقل للأعلى';

  @override
  String get sortPriceHighLow => 'السعر: من الأعلى للأقل';

  @override
  String get sortNameAz => 'الاسم: أ–ي';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get applyLabel => 'تطبيق';

  @override
  String get clearLabel => 'مسح';

  @override
  String resultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get searchHint => 'ابحث عن المنتجات';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get comingSoonBody => 'سيتوفّر هذا القسم في مرحلة لاحقة.';

  @override
  String get badgeNew => 'جديد';

  @override
  String get badgeBestseller => 'الأكثر مبيعًا';

  @override
  String get priceFrom => 'ابتداءً من';

  @override
  String get productAddToCart => 'أضف إلى السلة';

  @override
  String get productOutOfStock => 'غير متوفّر';

  @override
  String get tabDescription => 'الوصف';

  @override
  String get tabDetails => 'التفاصيل';

  @override
  String get tabReviews => 'المراجعات';

  @override
  String get specSku => 'رقم المنتج';

  @override
  String get reviewsEmptyTitle => 'لا توجد مراجعات بعد';

  @override
  String get reviewsEmptyBody => 'كن أوّل من يقيّم هذا المنتج.';

  @override
  String reviewsSummary(int rating, int count) {
    return 'تقييم $rating% · $count مراجعة';
  }

  @override
  String get menuShop => 'تسوّق';

  @override
  String get menuAccountSection => 'الحساب';

  @override
  String get menuLogOut => 'تسجيل الخروج';

  @override
  String get footerShop => 'تسوّق';

  @override
  String get footerSupport => 'الدعم';

  @override
  String get footerNewsletterTitle => 'اشترك في نشرتنا البريدية';

  @override
  String get footerNewsletterHint => 'البريد الإلكتروني';

  @override
  String get footerSubscribe => 'اشتراك';

  @override
  String get footerRights => '© زونزي بيوتي. جميع الحقوق محفوظة.';

  @override
  String get footerAbout => 'من نحن';

  @override
  String get footerContact => 'اتصل بنا';

  @override
  String get footerShipping => 'الشحن';

  @override
  String get footerReturns => 'الإرجاع';
}
