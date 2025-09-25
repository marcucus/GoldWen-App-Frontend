import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/services/accessibility_service.dart';

void main() {
  group('AccessibilityService', () {
    late AccessibilityService service;

    setUp(() {
      service = AccessibilityService();
    });

    test('initial state should have default values', () {
      expect(service.fontSize, AccessibilityFontSize.medium);
      expect(service.highContrast, false);
      expect(service.reducedMotion, false);
      expect(service.screenReaderEnabled, false);
      expect(service.textScaleFactor, 1.0);
      expect(service.isAccessibilityEnabled, false);
    });

    test('setFontSize should update fontSize and textScaleFactor', () async {
      await service.setFontSize(AccessibilityFontSize.large);
      
      expect(service.fontSize, AccessibilityFontSize.large);
      expect(service.textScaleFactor, 1.15);
    });

    test('setFontSize should update to xlarge correctly', () async {
      await service.setFontSize(AccessibilityFontSize.xlarge);
      
      expect(service.fontSize, AccessibilityFontSize.xlarge);
      expect(service.textScaleFactor, 1.3);
    });

    test('setFontSize should update to small correctly', () async {
      await service.setFontSize(AccessibilityFontSize.small);
      
      expect(service.fontSize, AccessibilityFontSize.small);
      expect(service.textScaleFactor, 0.85);
    });

    test('setHighContrast should update highContrast setting', () async {
      await service.setHighContrast(true);
      
      expect(service.highContrast, true);
      expect(service.isAccessibilityEnabled, true);
    });

    test('setReducedMotion should update reducedMotion setting', () async {
      await service.setReducedMotion(true);
      
      expect(service.reducedMotion, true);
      expect(service.isAccessibilityEnabled, true);
    });

    test('setScreenReaderEnabled should update screenReader setting', () async {
      await service.setScreenReaderEnabled(true);
      
      expect(service.screenReaderEnabled, true);
      expect(service.isAccessibilityEnabled, true);
    });

    test('getAnimationDuration should return zero duration for reduced motion', () {
      const defaultDuration = Duration(milliseconds: 300);
      
      // Without reduced motion
      expect(service.getAnimationDuration(defaultDuration), defaultDuration);
      
      // With reduced motion
      service.setReducedMotion(true);
      expect(service.getAnimationDuration(defaultDuration), Duration.zero);
    });

    test('getAnimationCurve should return linear curve for reduced motion', () {
      const defaultCurve = Curves.easeInOut;
      
      // Without reduced motion
      expect(service.getAnimationCurve(defaultCurve), defaultCurve);
      
      // With reduced motion
      service.setReducedMotion(true);
      expect(service.getAnimationCurve(defaultCurve), Curves.linear);
    });

    test('exportSettings should return correct format', () async {
      await service.setFontSize(AccessibilityFontSize.large);
      await service.setHighContrast(true);
      await service.setReducedMotion(true);
      await service.setScreenReaderEnabled(true);
      
      final settings = service.exportSettings();
      
      expect(settings, {
        'fontSize': 'large',
        'highContrast': true,
        'reducedMotion': true,
        'screenReader': true,
      });
    });

    test('importSettings should update all settings correctly', () async {
      final settings = {
        'fontSize': 'xlarge',
        'highContrast': true,
        'reducedMotion': false,
        'screenReader': true,
      };
      
      await service.importSettings(settings);
      
      expect(service.fontSize, AccessibilityFontSize.xlarge);
      expect(service.highContrast, true);
      expect(service.reducedMotion, false);
      expect(service.screenReaderEnabled, true);
    });

    test('importSettings should handle invalid fontSize gracefully', () async {
      final settings = {
        'fontSize': 'invalid_size',
        'highContrast': false,
      };
      
      await service.importSettings(settings);
      
      // Should default to medium for invalid fontSize
      expect(service.fontSize, AccessibilityFontSize.medium);
      expect(service.highContrast, false);
    });

    group('AccessibilityFontSize enum', () {
      test('should have correct names', () {
        expect(AccessibilityFontSize.small.name, 'small');
        expect(AccessibilityFontSize.medium.name, 'medium');
        expect(AccessibilityFontSize.large.name, 'large');
        expect(AccessibilityFontSize.xlarge.name, 'xlarge');
      });

      test('should have correct display names', () {
        expect(AccessibilityFontSize.small.displayName, 'Petite');
        expect(AccessibilityFontSize.medium.displayName, 'Normale');
        expect(AccessibilityFontSize.large.displayName, 'Grande');
        expect(AccessibilityFontSize.xlarge.displayName, 'Très grande');
      });
    });

    test('isAccessibilityEnabled should be true when any setting is enabled', () async {
      expect(service.isAccessibilityEnabled, false);
      
      await service.setFontSize(AccessibilityFontSize.large);
      expect(service.isAccessibilityEnabled, true);
      
      await service.setFontSize(AccessibilityFontSize.medium);
      expect(service.isAccessibilityEnabled, false);
      
      await service.setHighContrast(true);
      expect(service.isAccessibilityEnabled, true);
      
      await service.setHighContrast(false);
      await service.setReducedMotion(true);
      expect(service.isAccessibilityEnabled, true);
      
      await service.setReducedMotion(false);
      await service.setScreenReaderEnabled(true);
      expect(service.isAccessibilityEnabled, true);
    });
  });
}