import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Called whenever the backend rejects a request with 401 (expired/invalid
  /// token). Registered in main.dart to log the user out and return to login.
  static void Function()? onUnauthorized;

  /// Returns true if the response is a 401; also fires [onUnauthorized] once.
  static bool handleUnauthorized(int statusCode) {
    if (statusCode == 401) {
      onUnauthorized?.call();
      return true;
    }
    return false;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      // Skip ngrok's free-plan HTML interstitial so we always get JSON back.
      'ngrok-skip-browser-warning': 'true',
    };
  }

  static Map<String, String> getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      // Skip ngrok's free-plan HTML interstitial so we always get JSON back.
      'ngrok-skip-browser-warning': 'true',
    };
  }
}
