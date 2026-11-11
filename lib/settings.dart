class AppSettings {
  ///
  ///Basic setup details
  ///
  ///App Name
  static const String appName = 'Alee Customer App';
  static const String packageName = 'com.aleeshein.customer';
  static const String iosPackage = 'com.alee.shein';
  static const String iosLink = '';
  static const String appStoreId = '123456789';
  //change this with your client secret and API urls

  static const String baseUrl = 'https://alee-iq.com/app/v1/api/';
  static const String chatBaseUrl = "https://alee-iq.com/app/v1/Chat_Api/";

  static const String deepLinkUrlPrefix = 'https://eshopwrteamin.page.link';
  static const String deepLinkName = 'eshop.com';
  static const String shareNavigationWebUrl = "alee-iq.com";

  static const bool disableDarkTheme = false;

  static const String defaultLanguageCode = "en";
  static const String defaultCountryCode = 'IQ';

  static const int decimalPoints = 0;

  static const int timeOut = 50;
  static const int perPage = 10;

  ///Below declared variables and functions are useful for chat feature
  ///Chat Features utility
  static const String messagesLoadLimit = '30';
  static const double allowableTotalFileSizesInChatMediaInMB = 15.0;

  /// =========================================================================
  /// إعدادات بوابة الواتساب MSG91 (WhatsApp OTP Configuration)
  /// =========================================================================
  /// mode:
  /// - 'msg91_whatsapp_template': الإرسال المباشر عبر قالب واتساب من MSG91 WhatsApp Outbound API
  /// - 'msg91_otp_api': الإرسال والتحقق عبر MSG91 SendOTP v5 API
  /// - 'backend': الاعتماد على الباك إند الخاص بالتطبيق
  static const String whatsappOtpMode = 'msg91_whatsapp_template';

  /// مفتاح الربط الخاص بحسابك في MSG91 (AuthKey)
  static const String msg91AuthKey = '504458AImDWgf6tuON69e69c97P1';

  /// رقم الواتساب المربوط في حساب MSG91 بصيغة دولية بدون +
  static const String msg91IntegratedNumber = '9647867004005';

  /// بيانات قالب التحقق (Authentication Template) المعتمد في MSG91
  static const String msg91WhatsappTemplateName = 'otp_verification';
  static const String msg91WhatsappTemplateNamespace =
      'fb2754ce_eb28_485f_9d37_d2f9f00823a7';
  static const String msg91WhatsappTemplateLang = 'ar';
  static const bool msg91WhatsappTemplateHasCopyButton = true;

  /// معرف قالب SendOTP (يُستخدم فقط في حال اختيار وضع 'msg91_otp_api')
  static const String msg91OtpTemplateId = '';

  /// مدة صلاحية رمز التحقق بالثواني (5 دقائق = 300 ثانية)
  static const int otpExpirySeconds = 300;
}
