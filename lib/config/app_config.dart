import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static Map<String, dynamic>? _data;

  static Future<void> load() async {
    if (_data != null) return;
    try {
      final raw = await rootBundle.loadString('assets/config/app_config.json');
      _data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _data = <String, dynamic>{};
    }
  }

  static String? getString(String key) {
    final v = _data?[key];
    return v == null ? null : v.toString();
  }
}
