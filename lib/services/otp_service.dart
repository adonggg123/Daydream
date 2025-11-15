import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OTPService {
  // EmailJS configuration
  // TODO: Replace these with your actual EmailJS credentials
  // You can get these from https://www.emailjs.com/
  static const String _emailJSPublicKey = 'mI_gSpaFUnnerLq6x'; // Public Key from EmailJS
  static const String _emailJSServiceID = 'service_czwe9x8'; // Service ID from EmailJS
  static const String _emailJSTemplateID = 'template_tvt2uyo'; // Template ID from EmailJS
  static const String _emailJSAPI = 'https://api.emailjs.com/api/v1.0/email/send';

  // Store generated OTPs temporarily (in production, use a more secure storage)
  static final Map<String, OTPData> _otpStorage = {};

  // Generate a 6-digit OTP
  static String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via EmailJS
  static Future<void> sendOTP(String email) async {
    try {
      // Generate OTP
      final otp = _generateOTP();
      
      // Store OTP with expiration time (5 minutes)
      _otpStorage[email] = OTPData(
        otp: otp,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      // Prepare EmailJS request
      final response = await http.post(
        Uri.parse(_emailJSAPI),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _emailJSServiceID,
          'template_id': _emailJSTemplateID,
          'user_id': _emailJSPublicKey,
          'template_params': {
            'to_email': email,
            'to_name': email.split('@')[0],
            'otp_code': otp,
            'message': 'Your verification code is: $otp',
          },
        }),
      );

      if (response.statusCode == 200) {
        // Success - OTP sent
        return;
      } else {
        // Remove stored OTP on failure
        _otpStorage.remove(email);
        throw 'Failed to send OTP. Status code: ${response.statusCode}';
      }
    } catch (e) {
      // Remove stored OTP on error
      _otpStorage.remove(email);
      throw 'Error sending OTP: ${e.toString()}';
    }
  }

  // Verify OTP
  static bool verifyOTP(String email, String otp) {
    final otpData = _otpStorage[email];
    
    if (otpData == null) {
      return false; // No OTP found for this email
    }

    // Check if OTP has expired
    if (DateTime.now().isAfter(otpData.expiresAt)) {
      _otpStorage.remove(email);
      return false; // OTP expired
    }

    // Verify OTP
    if (otpData.otp == otp) {
      // Remove OTP after successful verification
      _otpStorage.remove(email);
      return true;
    }

    return false; // Invalid OTP
  }

  // Check if OTP exists for email
  static bool hasOTP(String email) {
    final otpData = _otpStorage[email];
    if (otpData == null) {
      return false;
    }

    // Check if expired
    if (DateTime.now().isAfter(otpData.expiresAt)) {
      _otpStorage.remove(email);
      return false;
    }

    return true;
  }

  // Clear expired OTPs (can be called periodically)
  static void clearExpiredOTPs() {
    _otpStorage.removeWhere((email, otpData) {
      return DateTime.now().isAfter(otpData.expiresAt);
    });
  }

  // Remove OTP (useful for cleanup)
  static void removeOTP(String email) {
    _otpStorage.remove(email);
  }
}

class OTPData {
  final String otp;
  final DateTime expiresAt;

  OTPData({
    required this.otp,
    required this.expiresAt,
  });
}

