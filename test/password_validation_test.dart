import 'package:flutter_test/flutter_test.dart';

/// Tests for password validation during registration
void main() {
  group('Password Validation Tests', () {
    /// Helper function to validate password according to the requirements
    String? validatePassword(String? value, {required bool isSignUp}) {
      if (value == null || value.isEmpty) {
        return 'Veuillez entrer votre mot de passe';
      }
      if (isSignUp) {
        if (value.length < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Le mot de passe doit contenir au moins une majuscule';
        }
        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
          return 'Le mot de passe doit contenir au moins un caractère spécial';
        }
      }
      return null;
    }

    test('should require password field to be non-empty', () {
      expect(
        validatePassword('', isSignUp: true),
        equals('Veuillez entrer votre mot de passe'),
      );
      expect(
        validatePassword(null, isSignUp: true),
        equals('Veuillez entrer votre mot de passe'),
      );
    });

    test('should require at least 6 characters during signup', () {
      expect(
        validatePassword('Ab!12', isSignUp: true),
        equals('Le mot de passe doit contenir au moins 6 caractères'),
      );
      expect(
        validatePassword('Ab!', isSignUp: true),
        equals('Le mot de passe doit contenir au moins 6 caractères'),
      );
    });

    test('should require at least one uppercase letter during signup', () {
      expect(
        validatePassword('abc123!', isSignUp: true),
        equals('Le mot de passe doit contenir au moins une majuscule'),
      );
      expect(
        validatePassword('password!', isSignUp: true),
        equals('Le mot de passe doit contenir au moins une majuscule'),
      );
    });

    test('should require at least one special character during signup', () {
      expect(
        validatePassword('Abcd1234', isSignUp: true),
        equals('Le mot de passe doit contenir au moins un caractère spécial'),
      );
      expect(
        validatePassword('Password123', isSignUp: true),
        equals('Le mot de passe doit contenir au moins un caractère spécial'),
      );
    });

    test('should accept valid passwords with all requirements', () {
      expect(validatePassword('Abc123!', isSignUp: true), isNull);
      expect(validatePassword('Password123!', isSignUp: true), isNull);
      expect(validatePassword('MyP@ssw0rd', isSignUp: true), isNull);
      expect(validatePassword('Secure#Pass1', isSignUp: true), isNull);
      expect(validatePassword('Test@123', isSignUp: true), isNull);
    });

    test('should accept various special characters', () {
      expect(validatePassword('Test@123', isSignUp: true), isNull);
      expect(validatePassword('Test!123', isSignUp: true), isNull);
      expect(validatePassword('Test#123', isSignUp: true), isNull);
      expect(validatePassword('Test\$123', isSignUp: true), isNull);
      expect(validatePassword('Test%123', isSignUp: true), isNull);
      expect(validatePassword('Test^123', isSignUp: true), isNull);
      expect(validatePassword('Test&123', isSignUp: true), isNull);
      expect(validatePassword('Test*123', isSignUp: true), isNull);
      expect(validatePassword('Test(123)', isSignUp: true), isNull);
      expect(validatePassword('Test.123', isSignUp: true), isNull);
      expect(validatePassword('Test,123', isSignUp: true), isNull);
      expect(validatePassword('Test?123', isSignUp: true), isNull);
      expect(validatePassword('Test:123', isSignUp: true), isNull);
      expect(validatePassword('Test{123}', isSignUp: true), isNull);
      expect(validatePassword('Test<123>', isSignUp: true), isNull);
    });

    test('should not validate password on login (isSignUp = false)', () {
      // On login, any password should be accepted (validated by backend)
      expect(validatePassword('short', isSignUp: false), isNull);
      expect(validatePassword('nouppercase', isSignUp: false), isNull);
      expect(validatePassword('NoSpecial', isSignUp: false), isNull);
      expect(validatePassword('a', isSignUp: false), isNull);
    });

    test('should check validations in order: length, uppercase, special', () {
      // Length fails first
      expect(
        validatePassword('ab!', isSignUp: true),
        equals('Le mot de passe doit contenir au moins 6 caractères'),
      );
      
      // Length OK, uppercase fails next
      expect(
        validatePassword('abcdef!', isSignUp: true),
        equals('Le mot de passe doit contenir au moins une majuscule'),
      );
      
      // Length and uppercase OK, special fails last
      expect(
        validatePassword('Abcdef', isSignUp: true),
        equals('Le mot de passe doit contenir au moins un caractère spécial'),
      );
    });

    test('should handle edge cases with multiple uppercase and special chars', () {
      expect(validatePassword('ABC!!!123', isSignUp: true), isNull);
      expect(validatePassword('TEST@#@#@#123', isSignUp: true), isNull);
      expect(validatePassword('UPPER!@#lower', isSignUp: true), isNull);
    });

    test('should handle passwords with numbers and letters', () {
      expect(validatePassword('Test123!', isSignUp: true), isNull);
      expect(validatePassword('Pass1234@', isSignUp: true), isNull);
      expect(validatePassword('1234Test!', isSignUp: true), isNull);
    });

    test('should handle long passwords', () {
      expect(
        validatePassword('ThisIsAVeryLongPassword123!WithManyCharacters', isSignUp: true),
        isNull,
      );
      expect(
        validatePassword('SuperLongP@ssw0rdWithLotsOfCharacters123456789', isSignUp: true),
        isNull,
      );
    });

    test('should handle unicode and accented characters', () {
      // These should still require special chars from the defined set
      expect(
        validatePassword('Motdépasse123', isSignUp: true),
        equals('Le mot de passe doit contenir au moins un caractère spécial'),
      );
      expect(
        validatePassword('Çàéêù123', isSignUp: true),
        equals('Le mot de passe doit contenir au moins un caractère spécial'),
      );
      
      // But should be valid with special chars
      expect(validatePassword('Motdépasse123!', isSignUp: true), isNull);
    });
  });
}
