import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gerçek telefon araması başlatma servisi.
/// `url_launcher` kullanarak cihazın telefon arayıcısını tetikler.
class PhoneCallService {
  /// Telefon numarasındaki parantez, tire, boşluk gibi gereksiz karakterleri temizler.
  static String cleanPhoneNumber(String phoneNumber) {
    // Sadece rakamlar ve varsa baştaki '+' karakterini korur
    final trimmed = phoneNumber.trim();
    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  /// Verilen telefon numarasının aranabilir olup olmadığını denetler.
  static Future<bool> canCall(String phoneNumber) async {
    final clean = cleanPhoneNumber(phoneNumber);
    if (clean.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: clean);
    try {
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('canLaunchUrl error: $e');
      return false;
    }
  }

  /// Telefon arama ekranını açar.
  /// Başarıyla başlatıldıysa `true`, aksi halde `false` döner.
  static Future<bool> makeCall(String phoneNumber) async {
    final clean = cleanPhoneNumber(phoneNumber);
    if (clean.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // canLaunchUrl false dönerse bile (özellikle bazı Android sürümlerinde) direkt dene
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Phone call launch error: $e');
      return false;
    }
  }
}
