import 'package:flutter_test/flutter_test.dart';

/// Tests for password confirmation validation during registration
void main() {
  group('Password Confirmation Validation Tests', () {
    /// Helper function to validate password confirmation
    String? validatePasswordConfirmation(
      String? confirmValue,
      String passwordValue,
      {required bool isSignUp}
    ) {
      if (!isSignUp) {
        return null; // No confirmation needed for login
      }
      
      if (confirmValue == null || confirmValue.isEmpty) {
        return 'Veuillez confirmer votre mot de passe';
      }
      if (confirmValue != passwordValue) {
        return 'Les mots de passe ne correspondent pas';
      }
      return null;
    }

    test('should require confirmation password field to be non-empty during signup', () {
      expect(
        validatePasswordConfirmation('', 'Password123!', isSignUp: true),
        equals('Veuillez confirmer votre mot de passe'),
      );
      expect(
        validatePasswordConfirmation(null, 'Password123!', isSignUp: true),
        equals('Veuillez confirmer votre mot de passe'),
      );
    });

    test('should require passwords to match during signup', () {
      expect(
        validatePasswordConfirmation('Password123!', 'DifferentPass123!', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
      expect(
        validatePasswordConfirmation('Test@123', 'Test@124', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
      expect(
        validatePasswordConfirmation('MyPass!', 'mypass!', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
    });

    test('should accept matching passwords during signup', () {
      expect(
        validatePasswordConfirmation('Password123!', 'Password123!', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Test@123', 'Test@123', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('MyP@ssw0rd', 'MyP@ssw0rd', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Secure#Pass1', 'Secure#Pass1', isSignUp: true),
        isNull,
      );
    });

    test('should not validate confirmation on login (isSignUp = false)', () {
      // On login, confirmation is not needed
      expect(
        validatePasswordConfirmation('', 'Password123!', isSignUp: false),
        isNull,
      );
      expect(
        validatePasswordConfirmation(null, 'Password123!', isSignUp: false),
        isNull,
      );
      expect(
        validatePasswordConfirmation('different', 'Password123!', isSignUp: false),
        isNull,
      );
    });

    test('should handle edge cases with special characters', () {
      expect(
        validatePasswordConfirmation('P@ss!123', 'P@ss!123', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Test#$%123', 'Test#$%123', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('P@ss!123', 'P@ss!124', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
    });

    test('should handle edge cases with spaces', () {
      expect(
        validatePasswordConfirmation('Pass 123!', 'Pass 123!', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Pass 123!', 'Pass123!', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
    });

    test('should handle long passwords', () {
      const longPassword = 'ThisIsAVeryLongPassword123!WithManyCharacters';
      expect(
        validatePasswordConfirmation(longPassword, longPassword, isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation(longPassword, '$longPassword!', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
    });

    test('should handle unicode and accented characters', () {
      expect(
        validatePasswordConfirmation('Motdépasse123!', 'Motdépasse123!', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Çàéêù123!', 'Çàéêù123!', isSignUp: true),
        isNull,
      );
      expect(
        validatePasswordConfirmation('Motdépasse123!', 'Motdepasse123!', isSignUp: true),
        equals('Les mots de passe ne correspondent pas'),
      );
    });
  });
}
