import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:goldwen_app/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    test('should initialize with system theme mode', () {
      expect(themeProvider.themeMode, AppThemeMode.system);
    });

    test('should change theme mode', () async {
      await themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.themeMode, AppThemeMode.dark);
      expect(themeProvider.isDarkMode, true);

      await themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.themeMode, AppThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('should return correct logo asset for theme', () {
      // Test light theme
      themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.currentLogoAsset, 'assets/images/logo_light.png');

      // Test dark theme
      themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.currentLogoAsset, 'assets/images/logo_dark.png');
    });

    test('should return app icon asset based on current mode', () {
      themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.appIconAsset, contains('logo_light.png'));

      themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.appIconAsset, contains('logo_dark.png'));
    });
  });
}