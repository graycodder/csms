import 'package:url_launcher/url_launcher.dart';

class AppLauncherUtils {
  /// Launches the phone dialer with the given [phoneNumber].
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  /// Launches WhatsApp with a pre-filled [message] to the [phoneNumber].
  static Future<void> launchWhatsApp(String phoneNumber, String message, {String defaultCountryCode = '91'}) async {
    // Basic normalization of phone number (remove spaces and plus)
    String normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Add country code if missing (e.g. if length is 10 and it's an Indian number)
    // Here we'll be more generic: if it's less than 11 digits, we assume country code is missing
    if (normalizedPhone.length <= 10 && !normalizedPhone.startsWith(defaultCountryCode)) {
      normalizedPhone = '$defaultCountryCode$normalizedPhone';
    }
    
    final String url = "whatsapp://send?phone=$normalizedPhone&text=${Uri.encodeFull(message)}";
    final Uri launchUri = Uri.parse(url);
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Fallback for web or if whatsapp:// fails
      final String webUrl = "https://wa.me/$normalizedPhone?text=${Uri.encodeFull(message)}";
      final Uri webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
