/// إعدادات التطبيق المركزية
class AppConfig {
  AppConfig._();

  // ===== Supabase =====
  static const String supabaseUrl = 'https://cpsjclmemsvafokternd.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_wpSNO0RzeHnETSXfI0yHWA_jiK0lY_H';

  // ===== معلومات التواصل والدعم =====
  static const String supportEmail = 'smartaccountant.support@atomicmail.io';
  static const String appName = 'المحاسب الذكي';
  static const String appNameEn = 'Smart Accountant';

  // ===== الاشتراك والدفع =====
  static const int trialDays = 14; // مدة التجربة المجانية بالأيام
  static const int dryMonths = 3;  // الأشهر الجافة قبل الحذف
  static const int demoResetDays = 10; // إعادة تعيين الديمو كل 10 أيام
  static const String usdtWalletAddress = 'YOUR_USDT_WALLET';
  static const String shamCashNumber = 'YOUR_SHAM_NUMBER';
  static const String supportWhatsApp = 'https://wa.me/YOUR_NUMBER';

  // ===== باقات الاشتراك =====
  static const Map<int, double> planPrices = {
    1: 5.0,   // شهري
    3: 13.0,  // 3 أشهر
    6: 24.0,  // 6 أشهر
    12: 42.0, // 12 شهر
    24: 72.0, // 24 شهر
  };

  // ===== سياسة الفواتير =====
  static const int editGraceHours = 4; // فترة السماح لتعديل الفاتورة

  // ===== Deep Link =====
  static const String deepLinkScheme = 'smartaccountant';
  static const String deepLinkHost = 'login-callback';

  // ===== إعدادات الأمان =====
  static const int autoLogoutMinutes = 30; // تسجيل خروج تلقائي بعد 30 دقيقة
}
