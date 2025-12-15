import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ar', ''),
  ];

  // Auth
  String get login => _localizedValues[locale.languageCode]?['login'] ?? 'Login';
  String get signUp => _localizedValues[locale.languageCode]?['signUp'] ?? 'Sign Up';
  String get emailAddress => _localizedValues[locale.languageCode]?['emailAddress'] ?? 'Email address';
  String get password => _localizedValues[locale.languageCode]?['password'] ?? 'Password';
  String get forgotPassword => _localizedValues[locale.languageCode]?['forgotPassword'] ?? 'Forgot Password?';
  String get dontHaveAccount => _localizedValues[locale.languageCode]?['dontHaveAccount'] ?? "Don't have an account?";
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]?['alreadyHaveAccount'] ?? 'Already have an account?';
  String get fullName => _localizedValues[locale.languageCode]?['fullName'] ?? 'Full name';
  String get phoneNumber => _localizedValues[locale.languageCode]?['phoneNumber'] ?? 'Phone Number';
  String get setPassword => _localizedValues[locale.languageCode]?['setPassword'] ?? 'Set password';
  String get reEnterPassword => _localizedValues[locale.languageCode]?['reEnterPassword'] ?? 'Re-enter password';
  String get acceptTerms => _localizedValues[locale.languageCode]?['acceptTerms'] ?? 'Accept our Terms of Use and our Privacy Policy';
  
  // Home
  String get laundry => _localizedValues[locale.languageCode]?['laundry'] ?? 'Laundry';
  String get theLaundryApp => _localizedValues[locale.languageCode]?['theLaundryApp'] ?? 'The laundry App';
  String get searchByStore => _localizedValues[locale.languageCode]?['searchByStore'] ?? 'Search by Store';
  String get services => _localizedValues[locale.languageCode]?['services'] ?? 'Services';
  String get nearbyLaundries => _localizedValues[locale.languageCode]?['nearbyLaundries'] ?? 'Nearby Laundries';
  String get viewAll => _localizedValues[locale.languageCode]?['viewAll'] ?? 'View All';
  
  // Services
  String get quickWash => _localizedValues[locale.languageCode]?['quickWash'] ?? 'Quick Wash';
  String get standard => _localizedValues[locale.languageCode]?['standard'] ?? 'Standard';
  String get premium => _localizedValues[locale.languageCode]?['premium'] ?? 'Premium';
  
  // Basket
  String get myBasket => _localizedValues[locale.languageCode]?['myBasket'] ?? 'My Basket';
  String get emptyBasket => _localizedValues[locale.languageCode]?['emptyBasket'] ?? "Oops! Your Basket is empty!";
  String get startAdding => _localizedValues[locale.languageCode]?['startAdding'] ?? 'Start Adding';
  String get placeOrder => _localizedValues[locale.languageCode]?['placeOrder'] ?? 'Place Order';
  
  // Orders
  String get myOrders => _localizedValues[locale.languageCode]?['myOrders'] ?? 'My Orders';
  String get active => _localizedValues[locale.languageCode]?['active'] ?? 'Active';
  String get completed => _localizedValues[locale.languageCode]?['completed'] ?? 'Completed';
  String get cancelled => _localizedValues[locale.languageCode]?['cancelled'] ?? 'Cancelled';
  String get viewDetails => _localizedValues[locale.languageCode]?['viewDetails'] ?? 'View Details';
  String get trackYourPickup => _localizedValues[locale.languageCode]?['trackYourPickup'] ?? 'Track your Pickup';
  
  // Order Success
  String get orderSuccessful => _localizedValues[locale.languageCode]?['orderSuccessful'] ?? 'Order Successful!';
  String get orderPlacedMessage => _localizedValues[locale.languageCode]?['orderPlacedMessage'] ?? 'Your Order successfully placed keep your clothes ready!';
  String get backToHome => _localizedValues[locale.languageCode]?['backToHome'] ?? 'Back to Home';
  
  // Common
  String get confirm => _localizedValues[locale.languageCode]?['confirm'] ?? 'Confirm';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Edit';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get retry => _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login': 'Login',
      'signUp': 'Sign Up',
      'emailAddress': 'Email address',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'fullName': 'Full name',
      'phoneNumber': 'Phone Number',
      'setPassword': 'Set password',
      'reEnterPassword': 'Re-enter password',
      'acceptTerms': 'Accept our Terms of Use and our Privacy Policy',
      'laundry': 'Laundry',
      'theLaundryApp': 'The laundry App',
      'searchByStore': 'Search by Store',
      'services': 'Services',
      'nearbyLaundries': 'Nearby Laundries',
      'viewAll': 'View All',
      'quickWash': 'Quick Wash',
      'standard': 'Standard',
      'premium': 'Premium',
      'myBasket': 'My Basket',
      'emptyBasket': "Oops! Your Basket is empty!",
      'startAdding': 'Start Adding',
      'placeOrder': 'Place Order',
      'myOrders': 'My Orders',
      'active': 'Active',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'viewDetails': 'View Details',
      'trackYourPickup': 'Track your Pickup',
      'orderSuccessful': 'Order Successful!',
      'orderPlacedMessage': 'Your Order successfully placed keep your clothes ready!',
      'backToHome': 'Back to Home',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
    },
    'ar': {
      // Arabic translations can be added here later
      'login': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'emailAddress': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'fullName': 'الاسم الكامل',
      'phoneNumber': 'رقم الهاتف',
      'setPassword': 'تعيين كلمة المرور',
      'reEnterPassword': 'أعد إدخال كلمة المرور',
      'acceptTerms': 'أوافق على شروط الاستخدام وسياسة الخصوصية',
      'laundry': 'مغسلة',
      'theLaundryApp': 'تطبيق المغسلة',
      'searchByStore': 'البحث عن المتجر',
      'services': 'الخدمات',
      'nearbyLaundries': 'المغاسل القريبة',
      'viewAll': 'عرض الكل',
      'quickWash': 'غسيل سريع',
      'standard': 'عادي',
      'premium': 'مميز',
      'myBasket': 'سلة التسوق',
      'emptyBasket': 'عذراً! سلة التسوق فارغة!',
      'startAdding': 'ابدأ الإضافة',
      'placeOrder': 'تقديم الطلب',
      'myOrders': 'طلباتي',
      'active': 'نشط',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'viewDetails': 'عرض التفاصيل',
      'trackYourPickup': 'تتبع الاستلام',
      'orderSuccessful': 'تم الطلب بنجاح!',
      'orderPlacedMessage': 'تم تقديم طلبك بنجاح، احتفظ بملابسك جاهزة!',
      'backToHome': 'العودة للرئيسية',
      'confirm': 'تأكيد',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'edit': 'تعديل',
      'delete': 'حذف',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

