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
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeWhite => 'أبيض';

  @override
  String get themeBlack => 'أسود';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get versionLabel => 'الإصدار';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionCopy => 'نسخ';

  @override
  String get actionLinkCopied => 'تم نسخ الرابط';

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
  String get settingsConnectionTest => 'اختبار الاتصال';

  @override
  String get settingsConnectionTestSubtitle =>
      'تحقّق من الاتصال المباشر بالمتجر';

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
  String get homeNewArrivals => 'وصل حديثًا';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeAnnouncement => 'شحن مجاني للطلبات فوق 150 درهمًا';

  @override
  String get homeTrustOriginalTitle => 'أصلي 100%';

  @override
  String get homeTrustOriginalBody => 'منتجات أصلية مضمونة';

  @override
  String get homeTrustDeliveryTitle => 'توصيل مجاني';

  @override
  String get homeTrustDeliveryBody => 'للطلبات فوق 150 درهمًا';

  @override
  String get homeTrustServiceTitle => 'خدمة العملاء';

  @override
  String get homeTrustServiceBody => 'من 10 صباحًا حتى 10 مساءً';

  @override
  String get homeHeroEyebrow => 'تشكيلة جديدة';

  @override
  String get homeHeroTitle => 'جمالكِ بأسلوبكِ';

  @override
  String get homeHeroSubtitle => 'علامات أصلية مختارة لدولة الإمارات';

  @override
  String get homeHeroCta => 'تسوّق الآن';

  @override
  String get categoriesSubtitle => 'تسوّقي حسب ما تحبين';

  @override
  String categoryProductCount(int count) {
    return '$count منتج';
  }

  @override
  String get filtersLabel => 'تصفية';

  @override
  String get filterPriceLabel => 'السعر';

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
  String get authSignInTitle => 'تسجيل الدخول';

  @override
  String get authSignInWelcome => 'مرحبًا بعودتك';

  @override
  String get authSignInSubtitle => 'سجّل الدخول لمتابعة التسوّق';

  @override
  String get authSignUpTitle => 'إنشاء حساب';

  @override
  String get authSignUpSubtitle =>
      'انضم إلى زونزي لإتمام الطلب بشكل أسرع وتتبّع الطلبات وعروض حصرية.';

  @override
  String get authAgreeTerms => 'أوافق على شروط الخدمة وسياسة الخصوصية';

  @override
  String get authForgotTitle => 'هل نسيت كلمة المرور؟';

  @override
  String get authForgotSubmit => 'إرسال رابط إعادة التعيين';

  @override
  String get fieldEmail => 'البريد الإلكتروني';

  @override
  String get fieldPassword => 'كلمة المرور';

  @override
  String get fieldFirstName => 'الاسم الأول';

  @override
  String get fieldLastName => 'اسم العائلة';

  @override
  String get authForgotLink => 'نسيت كلمة المرور؟';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authSignUpLink => 'إنشاء حساب';

  @override
  String get authForgotIntro =>
      'لا تقلق! أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get authForgotSent =>
      'إذا كان هذا البريد مسجّلاً، فسيصلك رابط إعادة التعيين قريبًا.';

  @override
  String get authHaveResetCode => 'لديّ رمز إعادة التعيين';

  @override
  String get authResetTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get authResetIntro =>
      'أدخل الرمز من بريد إعادة التعيين واختر كلمة مرور جديدة.';

  @override
  String get authResetError =>
      'تعذّر إعادة تعيين كلمة المرور. تحقّق من الرمز وحاول مرة أخرى.';

  @override
  String get fieldResetCode => 'رمز إعادة التعيين';

  @override
  String get authSignInError => 'تعذّر تسجيل الدخول. يرجى التحقّق من بياناتك.';

  @override
  String get validationRequired => 'مطلوب';

  @override
  String get validationEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get validationPassword => 'استخدم 8 أحرف على الأقل';

  @override
  String get accountGuestTitle => 'حساب زونزي الخاص بك';

  @override
  String get accountGuestBody =>
      'سجّل الدخول لتتبّع الطلبات وحفظ العناوين وإتمام الشراء بشكل أسرع.';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountHeading => 'حسابي';

  @override
  String get accountAbout => 'عن زونزي';

  @override
  String get accountOrders => 'طلباتي';

  @override
  String get accountAddresses => 'العناوين المحفوظة';

  @override
  String get accountHelp => 'المساعدة والأسئلة الشائعة';

  @override
  String get helpIntro =>
      'إجابات عن الأسئلة الشائعة. ما زلت بحاجة إلى مساعدة؟ تواصل مع فريقنا أدناه.';

  @override
  String get helpQOrders => 'كيف أتتبّع طلبي؟';

  @override
  String get helpAOrders => 'افتح حسابي ← طلباتي لعرض حالة كل طلب.';

  @override
  String get helpQPayments => 'ما طرق الدفع المتاحة؟';

  @override
  String get helpAPayments =>
      'البطاقات عبر Network International، وتابي (الدفع على 4 دفعات / الدفع لاحقًا) عند توفّرها في الدفع.';

  @override
  String get helpQDelivery => 'إلى أين توصّلون؟';

  @override
  String get helpADelivery => 'نوصّل إلى جميع أنحاء الإمارات العربية المتحدة.';

  @override
  String get helpQReturns => 'كيف أرجع منتجًا؟';

  @override
  String get helpAReturns =>
      'تواصل مع فريق الدعم خلال 14 يومًا من التوصيل لترتيب الإرجاع.';

  @override
  String get helpQLanguage => 'كيف أغيّر اللغة؟';

  @override
  String get helpALanguage =>
      'استخدم زر EN / العربية في القائمة أو في الإعدادات.';

  @override
  String get helpContactTitle => 'ما زلت بحاجة إلى مساعدة؟';

  @override
  String get helpEmailAction => 'مراسلة الدعم';

  @override
  String get helpWebsiteAction => 'زيارة zoonze.com';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsPromoTitle => 'العروض والتخفيضات';

  @override
  String get notificationsPromoBody =>
      'تلقَّ إشعارات بالتخفيضات والمنتجات الجديدة والعروض الحصرية.';

  @override
  String get notificationsOrdersNote =>
      'تُرسَل تحديثات الطلبات دائمًا لعمليات الشراء الخاصة بك.';

  @override
  String get cartTitle => 'السلة';

  @override
  String get cartHeading => 'سلّتي';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get cartSecureCheckout => 'الدفع الآمن';

  @override
  String get cartEmptyTitle => 'سلتك فارغة';

  @override
  String get cartEmptyBody => 'تصفّح المنتجات وأضف ما يعجبك.';

  @override
  String get cartContinueShopping => 'متابعة التسوّق';

  @override
  String get cartSubtotal => 'المجموع الفرعي';

  @override
  String get cartDiscount => 'الخصم';

  @override
  String get cartTotal => 'الإجمالي';

  @override
  String get cartCheckout => 'إتمام الشراء';

  @override
  String get cartCouponHint => 'رمز الخصم';

  @override
  String get cartApply => 'تطبيق';

  @override
  String get cartAdded => 'تمت الإضافة إلى السلة';

  @override
  String get cartCouponError => 'هذا الرمز غير صالح.';

  @override
  String get wishlistHeading => 'قائمة مفضلتي';

  @override
  String wishlistSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر محفوظة',
      one: 'عنصر محفوظ واحد',
    );
    return '$_temp0';
  }

  @override
  String get wishlistAddAll => 'أضف الكل إلى السلة';

  @override
  String get wishlistEmptyTitle => 'قائمة المفضلة فارغة';

  @override
  String get wishlistEmptyBody => 'اضغط على القلب في أي منتج لحفظه هنا.';

  @override
  String get wishlistSignInPrompt => 'سجّل الدخول لحفظ المنتجات في قائمتك.';

  @override
  String get wishlistGuestTitle => 'احفظ مفضّلاتك';

  @override
  String get wishlistGuestBody =>
      'سجّل الدخول للاحتفاظ بقائمة المفضلة عبر أجهزتك.';

  @override
  String get ordersEmpty => 'ليس لديك طلبات بعد.';

  @override
  String get ordersFilterAll => 'الكل';

  @override
  String get ordersFilterToReceive => 'قيد الاستلام';

  @override
  String get ordersFilterDelivered => 'تم التسليم';

  @override
  String get ordersFilterCancelled => 'ملغى';

  @override
  String get orderStatus => 'الحالة';

  @override
  String orderNumber(String number) {
    return 'الطلب رقم $number';
  }

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String get orderItemsSection => 'العناصر';

  @override
  String get orderTrackingSection => 'التتبّع';

  @override
  String get orderShippingLabel => 'الشحن';

  @override
  String get orderNoTracking => 'تظهر تفاصيل التتبّع هنا بمجرد شحن طلبك.';

  @override
  String get orderTrackingCopied => 'تم نسخ رقم التتبّع';

  @override
  String get orderViewDetails => 'عرض التفاصيل';

  @override
  String get addressesEmpty => 'لا توجد عناوين محفوظة بعد.';

  @override
  String get addressAdd => 'إضافة عنوان';

  @override
  String get addressEdit => 'تعديل العنوان';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionDelete => 'حذف';

  @override
  String get defaultBadge => 'افتراضي';

  @override
  String get fieldPhone => 'الهاتف';

  @override
  String get fieldStreet => 'عنوان الشارع';

  @override
  String get fieldCity => 'المدينة';

  @override
  String get fieldPostcode => 'الرمز البريدي';

  @override
  String get fieldRegion => 'المنطقة / الإمارة';

  @override
  String get fieldCountry => 'رمز الدولة';

  @override
  String get addressDefaultShipping => 'تعيين كعنوان شحن افتراضي';

  @override
  String get profileTitle => 'تعديل الملف الشخصي';

  @override
  String get profileSaved => 'تم تحديث الملف الشخصي';

  @override
  String get profilePasswordSection => 'تغيير كلمة المرور';

  @override
  String get fieldCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get fieldNewPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';

  @override
  String get reviewsWrite => 'اكتب مراجعة';

  @override
  String get reviewRating => 'تقييمك';

  @override
  String get reviewNickname => 'الاسم المستعار';

  @override
  String get reviewSummary => 'العنوان';

  @override
  String get reviewText => 'مراجعتك';

  @override
  String get reviewSubmit => 'إرسال المراجعة';

  @override
  String get reviewSubmitted => 'شكرًا لك! مراجعتك قيد المراجعة.';

  @override
  String get checkoutTitle => 'إتمام الشراء';

  @override
  String get checkoutContact => 'معلومات الاتصال';

  @override
  String get checkoutShippingAddress => 'عنوان الشحن';

  @override
  String get checkoutShippingMethod => 'طريقة الشحن';

  @override
  String get checkoutPayment => 'الدفع';

  @override
  String get checkoutSummary => 'ملخّص الطلب';

  @override
  String get checkoutContinue => 'متابعة';

  @override
  String get checkoutPlaceOrder => 'تأكيد الطلب';

  @override
  String get checkoutPayIn4 => 'أو 4 دفعات بدون فوائد';

  @override
  String get checkoutPayLater => 'ادفع لاحقًا بدون فوائد';

  @override
  String get checkoutCardInstalments => 'ادفع بالبطاقة على أقساط';

  @override
  String get checkoutFreeOrder => 'لا حاجة للدفع — إجمالي طلبك مجاني';

  @override
  String promoTabbyPayIn4(int count, String amount) {
    return 'أو $count دفعات بدون فوائد بقيمة $amount';
  }

  @override
  String get promoTabbyPayLater => 'أو ادفع لاحقًا بدون فوائد';

  @override
  String get promoTabbyCardInstalments => 'أو ادفع بالبطاقة على أقساط';

  @override
  String get paymentSessionUnavailable =>
      'تابي غير متاح لهذا الطلب. يرجى اختيار طريقة دفع أخرى.';

  @override
  String get fieldCountryLabel => 'الدولة';

  @override
  String get countryUae => 'الإمارات العربية المتحدة';

  @override
  String get paymentDeclined => 'تم رفض الدفع. يرجى اختيار طريقة دفع أخرى.';

  @override
  String get paymentFailed => 'تعذّر إتمام الدفع. يرجى المحاولة مرة أخرى.';

  @override
  String get paymentExpired =>
      'انتهت صلاحية جلسة الدفع. يرجى المحاولة مرة أخرى.';

  @override
  String get paymentProcessing =>
      'لا يزال الدفع قيد المعالجة. يرجى المحاولة بعد قليل.';

  @override
  String get completePaymentTitle => 'إتمام الدفع';

  @override
  String completePaymentBody(String number) {
    return 'تم تنفيذ الطلب $number وهو بانتظار الدفع. اختر طريقة الدفع المناسبة لك.';
  }

  @override
  String get completePaymentPayNow => 'ادفع الآن';

  @override
  String get completePaymentPayLater => 'سأدفع لاحقًا';

  @override
  String get orderSuccessTitle => 'تم تنفيذ الطلب!';

  @override
  String get orderPendingTitle => 'تم استلام طلبك';

  @override
  String orderSuccessBody(String number) {
    return 'شكرًا لك. رقم طلبك هو $number.';
  }

  @override
  String get orderNumberLabel => 'رقم الطلب';

  @override
  String get orderNumberCopied => 'تم نسخ رقم الطلب';

  @override
  String get paymentRedirectTitle => 'إتمام الدفع';

  @override
  String get paymentRedirectPending =>
      'تم استلام طلبك وهو بانتظار تأكيد الدفع. سنخطرك بمجرد إتمام الدفع.';

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
  String get footerNewsletterTitle => 'النشرة البريدية';

  @override
  String get footerNewsletterSubtitle =>
      'اشترك لتصلك العروض الخاصة وآخر المستجدات.';

  @override
  String get footerNewsletterHint => 'بريدك الإلكتروني';

  @override
  String get footerSubscribe => 'اشتراك';

  @override
  String get footerSubscribed => 'شكرًا! سنبقيك على اطّلاع.';

  @override
  String get footerRights => '© 2026 زونزي بيوتي · جميع الحقوق محفوظة.';

  @override
  String get footerTagline => 'وجهتك للجمال والعطور الأصلية في الإمارات.';

  @override
  String get footerAboutHeading => 'من نحن';

  @override
  String get footerAbout => 'من نحن';

  @override
  String get footerContact => 'اتصل بنا';

  @override
  String get footerStoreLocator => 'مواقع المتاجر';

  @override
  String get footerTrackOrder => 'تتبّع الطلب';

  @override
  String get footerShippingReturns => 'الشحن والإرجاع';

  @override
  String get footerFaqs => 'الأسئلة الشائعة';

  @override
  String get footerPrivacy => 'سياسة الخصوصية';

  @override
  String get footerTerms => 'شروط الخدمة';

  @override
  String get footerShipping => 'الشحن';

  @override
  String get footerReturns => 'الإرجاع';
}
