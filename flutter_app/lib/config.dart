import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultBaseUrl = 'https://findback.onrender.com';
  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('server_url') ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    _baseUrl = url;
  }
}
