import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isDarkMode = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPreferences();
    _updateSystemTheme();
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? AppThemeMode.system.index;
    _themeMode = AppThemeMode.values[themeIndex];
    _updateSystemTheme();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    _updateSystemTheme();
    notifyListeners();
  }

  void _updateSystemTheme() {
    switch (_themeMode) {
      case AppThemeMode.light:
        _isDarkMode = false;
        break;
      case AppThemeMode.dark:
        _isDarkMode = true;
        break;
      case AppThemeMode.system:
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
      case AppThemeMode.light:
        return 'assets/images/logo_light.png';
      case AppThemeMode.dark:
        return 'assets/images/logo_dark.png';
      case AppThemeMode.system:
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