import 'dart:convert';
import 'dart:math';
import 'package:eshop/settings.dart';
import 'package:http/http.dart' as http;

/// خدمة إرسال والتحقق من رمز التفعيل (OTP) عبر الواتساب باستخدام مزود الخدمة MSG91
class Msg91WhatsappService {
  static String? _lastGeneratedOtp;
  static String? _lastPhoneNumber;
  static DateTime? _otpGeneratedAt;

  /// تنسيق رقم الهاتف مع مفتاح الدولة بدون علامة (+) أو أصفار بادئة
  static String formatPhoneNumber(String countryCode, String mobileNumber) {
    String cleanCountry = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCountry.isEmpty) {
      cleanCountry = '964'; // مفتاح العراق الافتراضي إذا تم تمرير رمز الدولة النصي 'IQ'
    }
    String cleanMobile = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanMobile.startsWith('00')) {
      cleanMobile = cleanMobile.substring(2);
    } else if (cleanMobile.startsWith('0')) {
      cleanMobile = cleanMobile.substring(1);
    }
    if (cleanMobile.startsWith(cleanCountry)) {
      return cleanMobile;
    }
    return '$cleanCountry$cleanMobile';
  }

  /// توليد رمز تحقق عشوائي مكون من 6 أرقام
  static String _generateSixDigitOtp() {
    final random = Random.secure();
    int code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  /// التحقق مما إذا كان المستخدم قد قام بتعبئة مفاتيح MSG91 في settings.dart
  static bool get isDirectMsg91Configured {
    return AppSettings.msg91AuthKey.isNotEmpty &&
        AppSettings.msg91AuthKey != 'YOUR_MSG91_AUTH_KEY';
  }

  /// إرسال رمز التحقق عبر الواتساب
  static Future<Map<String, dynamic>> sendWhatsappOtp({
    required String countryCode,
    required String mobileNumber,
  }) async {
    final String fullMobile = formatPhoneNumber(countryCode, mobileNumber);

    if (AppSettings.whatsappOtpMode == 'msg91_otp_api') {
      return _sendViaMsg91OtpApi(fullMobile);
    } else if (AppSettings.whatsappOtpMode == 'msg91_whatsapp_template') {
      return _sendViaWhatsappTemplateApi(fullMobile);
    } else {
      return {
        'error': false,
        'message': 'OTP handled by backend',
      };
    }
  }

  /// الطريقة الأولى: الإرسال المباشر عبر قالب واتساب المعتمد في MSG91
  /// Endpoint: https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/
  static Future<Map<String, dynamic>> _sendViaWhatsappTemplateApi(
      String fullMobile) async {
    final String otpCode = _generateSixDigitOtp();
    _lastGeneratedOtp = otpCode;
    _lastPhoneNumber = fullMobile;
    _otpGeneratedAt = DateTime.now();

    final Uri url = Uri.parse(
        'https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/');

    final Map<String, dynamic> components = {
      "body_1": {
        "type": "text",
        "value": otpCode,
      }
    };

    if (AppSettings.msg91WhatsappTemplateHasCopyButton) {
      components["button_1"] = {
        "subtype": "url",
        "type": "text",
        "value": otpCode,
      };
    }

    final Map<String, dynamic> payload = {
      "integrated_number": AppSettings.msg91IntegratedNumber,
      "content_type": "template",
      "payload": {
        "messaging_product": "whatsapp",
        "type": "template",
        "template": {
          "name": AppSettings.msg91WhatsappTemplateName,
          "language": {
            "code": AppSettings.msg91WhatsappTemplateLang,
            "policy": "deterministic"
          },
          "namespace": AppSettings.msg91WhatsappTemplateNamespace,
          "to_and_components": [
            {
              "to": [fullMobile],
              "components": components,
            }
          ]
        }
      }
    };

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
              'authkey': AppSettings.msg91AuthKey,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: AppSettings.timeOut));

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      final String status =
          (responseData['status'] ?? responseData['type'] ?? '')
              .toString()
              .toLowerCase();

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          status != 'error' &&
          responseData['hasError'] != true) {
        return {
          'error': false,
          'message': responseData['message'] ?? 'تم إرسال رمز التحقق عبر الواتساب بنجاح',
        };
      } else {
        return {
          'error': true,
          'message': responseData['message'] ??
              responseData['errors']?.toString() ??
              'تعذر إرسال رمز التحقق عبر الواتساب',
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': e.toString(),
      };
    }
  }

  /// الطريقة الثانية: الإرسال عبر MSG91 SendOTP v5 API
  /// Endpoint: https://control.msg91.com/api/v5/otp
  static Future<Map<String, dynamic>> _sendViaMsg91OtpApi(
      String fullMobile) async {
    final Uri url = Uri.parse('https://control.msg91.com/api/v5/otp').replace(
      queryParameters: {
        'template_id': AppSettings.msg91OtpTemplateId,
        'mobile': fullMobile,
        'otp_length': '6',
      },
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
              'authkey': AppSettings.msg91AuthKey,
            },
          )
          .timeout(const Duration(seconds: AppSettings.timeOut));

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          (responseData['type']?.toString().toLowerCase() == 'success')) {
        return {
          'error': false,
          'message': responseData['message'] ?? 'تم إرسال رمز التحقق عبر الواتساب بنجاح',
        };
      } else {
        return {
          'error': true,
          'message': responseData['message'] ?? 'تعذر إرسال رمز التحقق عبر الواتساب',
        };
      }
    } catch (e) {
      return {
        'error': true,
        'message': e.toString(),
      };
    }
  }

  /// التحقق من صحة رمز الـ OTP المدخل من قبل المستخدم
  static Future<Map<String, dynamic>> verifyWhatsappOtp({
    required String countryCode,
    required String mobileNumber,
    required String enteredOtp,
  }) async {
    final String fullMobile = formatPhoneNumber(countryCode, mobileNumber);
    final String cleanOtp = enteredOtp.trim();

    if (AppSettings.whatsappOtpMode == 'msg91_otp_api') {
      final Uri url =
          Uri.parse('https://control.msg91.com/api/v5/otp/verify').replace(
        queryParameters: {
          'otp': cleanOtp,
          'mobile': fullMobile,
        },
      );

      try {
        final response = await http
            .get(
              url,
              headers: {
                'accept': 'application/json',
                'authkey': AppSettings.msg91AuthKey,
              },
            )
            .timeout(const Duration(seconds: AppSettings.timeOut));

        final Map<String, dynamic> responseData =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 &&
            responseData['type']?.toString().toLowerCase() == 'success') {
          return {
            'error': false,
            'message': responseData['message'] ?? 'تم التحقق من الرمز بنجاح',
          };
        } else {
          return {
            'error': true,
            'message': responseData['message'] ?? 'رمز التحقق غير صحيح',
          };
        }
      } catch (e) {
        return {
          'error': true,
          'message': e.toString(),
        };
      }
    } else if (AppSettings.whatsappOtpMode == 'msg91_whatsapp_template') {
      if (_lastGeneratedOtp == null || _lastPhoneNumber != fullMobile) {
        return {
          'error': true,
          'message': 'يرجى طلب رمز تحقق جديد أولاً',
        };
      }

      final int elapsedSeconds =
          DateTime.now().difference(_otpGeneratedAt!).inSeconds;
      if (elapsedSeconds > AppSettings.otpExpirySeconds) {
        return {
          'error': true,
          'message': 'انتهت صلاحية رمز التحقق، يرجى إعادة الإرسال',
        };
      }

      if (cleanOtp == _lastGeneratedOtp) {
        _lastGeneratedOtp = null;
        return {
          'error': false,
          'message': 'تم التحقق من الرمز بنجاح',
        };
      } else {
        return {
          'error': true,
          'message': 'رمز التحقق غير متطابق',
        };
      }
    } else {
      return {
        'error': true,
        'message': 'Unsupported mode for direct verification',
      };
    }
  }
}
