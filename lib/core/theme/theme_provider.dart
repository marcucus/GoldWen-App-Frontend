import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPreferences();
    _updateSystemTheme();
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _updateSystemTheme();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    _updateSystemTheme();
    notifyListeners();
  }

  void _updateSystemTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _isDarkMode = false;
        break;
      case ThemeMode.dark:
        _isDarkMode = true;
        break;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
        break;
    }
    
    // Update system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFF8),
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  String get currentLogoAsset {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'assets/images/logo_light.png';
      case ThemeMode.dark:
        return 'assets/images/logo_dark.png';
      case ThemeMode.system:
        return _isDarkMode 
            ? 'assets/images/logo_dark.png' 
            : 'assets/images/logo_light.png';
    }
  }

  String get appIconAsset {
    return _isDarkMode 
        ? 'assets/images/logo_dark.png' 
        : 'assets/images/logo_light.png';
  }
}