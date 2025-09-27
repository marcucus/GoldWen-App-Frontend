import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing accessibility settings and system preferences
class AccessibilityService extends ChangeNotifier {
  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _screenReaderKey = 'accessibility_screen_reader';

  // Accessibility settings
  AccessibilityFontSize _fontSize = AccessibilityFontSize.medium;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _screenReaderEnabled = false;

  // System settings (detected from device)
  bool _systemHighContrast = false;
  bool _systemReducedMotion = false;
  double _systemTextScaleFactor = 1.0;

  // Getters
  AccessibilityFontSize get fontSize => _fontSize;
  bool get highContrast => _highContrast || _systemHighContrast;
  bool get reducedMotion => _reducedMotion || _systemReducedMotion;
  bool get screenReaderEnabled => _screenReaderEnabled;
  double get textScaleFactor => _getScaleFactorForFontSize(_fontSize);
  bool get isAccessibilityEnabled => highContrast || reducedMotion || screenReaderEnabled || _fontSize != AccessibilityFontSize.medium;

  /// Initialize accessibility settings
  Future<void> initialize() async {
    await _loadSettings();
    await _detectSystemSettings();
    notifyListeners();
  }

  /// Load saved accessibility settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final fontSizeIndex = prefs.getInt(_fontSizeKey) ?? AccessibilityFontSize.medium.index;
      _fontSize = AccessibilityFontSize.values[fontSizeIndex];
      
      _highContrast = prefs.getBool(_highContrastKey) ?? false;
      _reducedMotion = prefs.getBool(_reducedMotionKey) ?? false;
      _screenReaderEnabled = prefs.getBool(_screenReaderKey) ?? false;
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
    }
  }

  /// Detect system accessibility settings
  Future<void> _detectSystemSettings() async {
    try {
      // Get system accessibility settings via platform channels
      final platformData = await _getSystemAccessibilityData();
      
      _systemHighContrast = platformData['highContrast'] ?? false;
      _systemReducedMotion = platformData['reducedMotion'] ?? false;
      _systemTextScaleFactor = (platformData['textScaleFactor'] ?? 1.0).toDouble();
      
      // Auto-enable screen reader detection if possible
      _screenReaderEnabled = _screenReaderEnabled || (platformData['screenReader'] ?? false);
    } catch (e) {
      debugPrint('Error detecting system accessibility settings: $e');
    }
  }

  /// Get system accessibility data from platform
  Future<Map<String, dynamic>> _getSystemAccessibilityData() async {
    try {
      const platform = MethodChannel('goldwen.app/accessibility');
      final result = await platform.invokeMethod('getSystemSettings');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      // Fallback to MediaQuery-based detection will be done in widgets
      return {};
    }
  }

  /// Update font size setting
  Future<void> setFontSize(AccessibilityFontSize fontSize) async {
    if (_fontSize == fontSize) return;
    
    _fontSize = fontSize;
    await _saveSettings();
    notifyListeners();
    
    // Announce change for screen readers
    if (screenReaderEnabled) {
      _announceChange('Font size changed to ${fontSize.name}');
    }
  }

  /// Update high contrast setting
  Future<void> setHighContrast(bool enabled) async {
    if (_highContrast == enabled) return;
    
    _highContrast = enabled;
    await _saveSettings();
    notifyListeners();
    
    if (screenReaderEnabled) {
      _announceChange(enabled ? 'High contrast enabled' : 'High contrast disabled');
    }
  }

  /// Update reduced motion setting
  Future<void> setReducedMotion(bool enabled) async {
    if (_reducedMotion == enabled) return;
    
    _reducedMotion = enabled;
    await _saveSettings();
    notifyListeners();
    
    if (screenReaderEnabled) {
      _announceChange(enabled ? 'Reduced motion enabled' : 'Reduced motion disabled');
    }
  }

  /// Update screen reader setting
  Future<void> setScreenReaderEnabled(bool enabled) async {
    if (_screenReaderEnabled == enabled) return;
    
    _screenReaderEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Save settings to local storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(_fontSizeKey, _fontSize.index);
      await prefs.setBool(_highContrastKey, _highContrast);
      await prefs.setBool(_reducedMotionKey, _reducedMotion);
      await prefs.setBool(_screenReaderKey, _screenReaderEnabled);
    } catch (e) {
      debugPrint('Error saving accessibility settings: $e');
    }
  }

  /// Get text scale factor for font size setting
  double _getScaleFactorForFontSize(AccessibilityFontSize size) {
    switch (size) {
      case AccessibilityFontSize.small:
        return 0.85;
      case AccessibilityFontSize.medium:
        return 1.0;
      case AccessibilityFontSize.large:
        return 1.15;
      case AccessibilityFontSize.xlarge:
        return 1.3;
    }
  }

  /// Announce accessibility changes to screen readers
  void _announceChange(String message) {
    try {
      SemanticsService.announce(message, TextDirection.ltr);
    } catch (e) {
      // SemanticsService might not be available on all Flutter versions
      print('Failed to announce accessibility change: $e');
    }
  }

  /// Get animation duration based on reduced motion setting
  Duration getAnimationDuration(Duration defaultDuration) {
    if (reducedMotion) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Get curve based on reduced motion setting
  Curve getAnimationCurve(Curve defaultCurve) {
    if (reducedMotion) {
      return Curves.linear;
    }
    return defaultCurve;
  }

  /// Export settings for backend sync
  Map<String, dynamic> exportSettings() {
    return {
      'fontSize': _fontSize.name,
      'highContrast': _highContrast,
      'reducedMotion': _reducedMotion,
      'screenReader': _screenReaderEnabled,
    };
  }

  /// Import settings from backend
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('fontSize')) {
        final fontSizeStr = settings['fontSize'] as String;
        final fontSize = AccessibilityFontSize.values.firstWhere(
          (size) => size.name == fontSizeStr,
          orElse: () => AccessibilityFontSize.medium,
        );
        await setFontSize(fontSize);
      }
      
      if (settings.containsKey('highContrast')) {
        await setHighContrast(settings['highContrast'] as bool);
      }
      
      if (settings.containsKey('reducedMotion')) {
        await setReducedMotion(settings['reducedMotion'] as bool);
      }
      
      if (settings.containsKey('screenReader')) {
        await setScreenReaderEnabled(settings['screenReader'] as bool);
      }
    } catch (e) {
      debugPrint('Error importing accessibility settings: $e');
    }
  }
}

/// Font size options for accessibility
enum AccessibilityFontSize {
  small,
  medium,
  large,
  xlarge;

  String get name {
    switch (this) {
      case AccessibilityFontSize.small:
        return 'small';
      case AccessibilityFontSize.medium:
        return 'medium';
      case AccessibilityFontSize.large:
        return 'large';
      case AccessibilityFontSize.xlarge:
        return 'xlarge';
    }
  }

  String get displayName {
    switch (this) {
      case AccessibilityFontSize.small:
        return 'Petite';
      case AccessibilityFontSize.medium:
        return 'Normale';
      case AccessibilityFontSize.large:
        return 'Grande';
      case AccessibilityFontSize.xlarge:
        return 'Très grande';
    }
  }
}