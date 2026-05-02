import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const String _themeBox = 'theme_settings';
  static const String _isDarkModeKey = 'is_dark_mode';

  static late Box<dynamic> _themeBoxInstance;

  static Box<dynamic> get themeBox => _themeBoxInstance;

  static Future<void> init() async {
    _themeBoxInstance = await Hive.openBox(_themeBox);
  }

  static bool get isDarkMode {
    return _themeBoxInstance.get(_isDarkModeKey, defaultValue: false) as bool;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _themeBoxInstance.put(_isDarkModeKey, isDark);
  }

  static Future<void> toggleDarkMode() async {
    await setDarkMode(!isDarkMode);
  }
}
