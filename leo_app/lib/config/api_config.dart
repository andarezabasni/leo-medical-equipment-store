import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _key = 'server_ip';
  static const String _defaultUrl = 'http://192.168.100.4:3000';

  static String baseUrl = _defaultUrl;

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw FormatException('URL tidak boleh kosong');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('Format address invalid');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    baseUrl = trimmed;
  }
}
