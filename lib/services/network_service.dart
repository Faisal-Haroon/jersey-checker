import 'dart:io';

class NetworkService {
  /// Checks whether the device has a real active internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final fallback = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 4));
      if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
