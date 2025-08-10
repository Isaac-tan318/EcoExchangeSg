import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _keyMode = 'themeModeIndex';
  static const _keySeed = 'themeSeedColor';
  static const _keyTextScale = 'textScale';

  ThemeMode _mode = ThemeMode.light;
  Color _seed = const Color(0xFF3D8259); // fallback green
  double _textScale = 1.0; // 0.9, 1.0, 1.15, 1.3

  ThemeMode get mode => _mode;
  Color get seedColor => _seed;
  double get textScale => _textScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_keyMode);
    final seedVal = prefs.getInt(_keySeed);
    final textScaleVal = prefs.getDouble(_keyTextScale);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      var loaded = ThemeMode.values[modeIndex];
      if (loaded == ThemeMode.system) {
        loaded = ThemeMode.light;
        await prefs.setInt(_keyMode, loaded.index);
      }
      _mode = loaded;
    }
    if (seedVal != null) {
      _seed = Color(seedVal);
    }
    if (textScaleVal != null && textScaleVal > 0) {
      _textScale = textScaleVal;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seed = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeed, color.value);
  }

  Future<void> setTextScale(double scale) async {
    // clamp to reasonable range
    final clamped = scale.clamp(0.8, 1.6).toDouble();
    _textScale = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, _textScale);
  }

  ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.light,
      ),
      fontFamily: 'Outfit',
      textTheme: Theme.of(context).textTheme.copyWith(
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400),
        bodyLarge: const TextStyle(fontSize: 18),
        labelLarge: const TextStyle(fontSize: 18),
      ),
    );
  }

  ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Outfit',
      textTheme: Theme.of(context).textTheme.copyWith(
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400),
        bodyLarge: const TextStyle(fontSize: 18),
        labelLarge: const TextStyle(fontSize: 18),
      ),
    );
  }

  // Reset theme preferences to app defaults and persist them
  Future<void> resetToDefaults() async {
    _mode = ThemeMode.light;
    _seed = const Color(0xFF3D8259); // default green
    _textScale = 1.0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, _mode.index);
    await prefs.setInt(_keySeed, _seed.value);
    await prefs.setDouble(_keyTextScale, _textScale);
  }
}
