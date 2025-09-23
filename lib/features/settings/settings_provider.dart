import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _kTheme = 'settings.theme';      // system/light/dark
  static const _kLocale = 'settings.locale';    // en/id
  static const _kSfw = 'settings.sfw';          // bool
  static const _kPreferEn = 'settings.prefer_en'; // bool

  ThemeMode _themeMode = ThemeMode.system;
  String _localeCode = 'en';
  bool _sfwOnly = true;
  bool _preferEnglishTitle = true;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  ThemeMode get themeMode => _themeMode;
  String get localeCode => _localeCode;
  bool get sfwOnly => _sfwOnly;
  bool get preferEnglishTitle => _preferEnglishTitle;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kTheme);
    final loc = prefs.getString(_kLocale);
    final sfw = prefs.getBool(_kSfw);
    final prefer = prefs.getBool(_kPreferEn);

    _themeMode = _toTheme(themeStr ?? 'system');
    _localeCode = (loc == 'id' || loc == 'en') ? loc! : 'en';
    _sfwOnly = sfw ?? true;
    _preferEnglishTitle = prefer ?? true;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, _themeToStr(m));
  }

  Future<void> setLocaleCode(String code) async {
    if (code != 'en' && code != 'id') return;
    _localeCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, code);
  }

  Future<void> setSfwOnly(bool v) async {
    _sfwOnly = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSfw, v);
  }

  Future<void> setPreferEnglishTitle(bool v) async {
    _preferEnglishTitle = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPreferEn, v);
  }

  // helpers
  static ThemeMode _toTheme(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeToStr(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
