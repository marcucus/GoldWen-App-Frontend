import 'package:flutter_test/flutter_test.dart';
import 'package:goldwen_app/core/utils/text_validator.dart';

void main() {
  group('TextValidator - Forbidden Words', () {
    test('should detect forbidden words in English', () {
      expect(
        TextValidator.validateForbiddenWords('This is fuck bad'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      expect(
        TextValidator.validateForbiddenWords('What a shit day'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should detect forbidden words in French', () {
      expect(
        TextValidator.validateForbiddenWords('Putain que c\'est nul'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      expect(
        TextValidator.validateForbiddenWords('Quel connard'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should handle case insensitive matching', () {
      expect(
        TextValidator.validateForbiddenWords('FUCK this'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      expect(
        TextValidator.validateForbiddenWords('PuTaIn'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should allow clean text', () {
      expect(
        TextValidator.validateForbiddenWords('Hello, how are you doing today?'),
        null,
      );
      
      expect(
        TextValidator.validateForbiddenWords('Bonjour, comment allez-vous?'),
        null,
      );
    });

    test('should handle empty or null text', () {
      expect(TextValidator.validateForbiddenWords(null), null);
      expect(TextValidator.validateForbiddenWords(''), null);
      expect(TextValidator.validateForbiddenWords('   '), null);
    });

    test('should detect leetspeak variations', () {
      expect(
        TextValidator.validateForbiddenWords('F0ck this sh1t'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should detect scam keywords', () {
      expect(
        TextValidator.validateForbiddenWords('Invest in bitcoin now'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      expect(
        TextValidator.validateForbiddenWords('Message me on whatsapp'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should detect social media platforms', () {
      expect(
        TextValidator.validateForbiddenWords('Add me on instagram'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      expect(
        TextValidator.validateForbiddenWords('Follow me on snapchat'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });
  });

  group('TextValidator - Contact Info', () {
    test('should detect email addresses', () {
      expect(
        TextValidator.validateContactInfo('Contact me at test@example.com'),
        'Le partage d\'informations de contact n\'est pas autorisé.',
      );
      
      expect(
        TextValidator.validateContactInfo('My email is john.doe@gmail.com'),
        'Le partage d\'informations de contact n\'est pas autorisé.',
      );
    });

    test('should detect phone numbers', () {
      expect(
        TextValidator.validateContactInfo('Call me at 0612345678'),
        'Le partage de numéros de téléphone n\'est pas autorisé.',
      );
      
      expect(
        TextValidator.validateContactInfo('My number is +33 6 12 34 56 78'),
        'Le partage de numéros de téléphone n\'est pas autorisé.',
      );
    });

    test('should detect URLs', () {
      expect(
        TextValidator.validateContactInfo('Visit my website www.example.com'),
        'Le partage de liens n\'est pas autorisé.',
      );
      
      expect(
        TextValidator.validateContactInfo('Check out https://example.com'),
        'Le partage de liens n\'est pas autorisé.',
      );
      
      expect(
        TextValidator.validateContactInfo('My site is example.fr'),
        'Le partage de liens n\'est pas autorisé.',
      );
    });

    test('should allow clean text without contact info', () {
      expect(
        TextValidator.validateContactInfo('I love traveling and photography'),
        null,
      );
    });

    test('should handle empty or null text', () {
      expect(TextValidator.validateContactInfo(null), null);
      expect(TextValidator.validateContactInfo(''), null);
      expect(TextValidator.validateContactInfo('   '), null);
    });
  });

  group('TextValidator - Spam Patterns', () {
    test('should detect excessive character repetition', () {
      expect(
        TextValidator.validateSpamPatterns('Hellooooooo everyone'),
        'Merci d\'éviter les répétitions excessives.',
      );
      
      expect(
        TextValidator.validateSpamPatterns('Yesssssss!!!!!!'),
        'Merci d\'éviter les répétitions excessives.',
      );
    });

    test('should detect all caps text', () {
      expect(
        TextValidator.validateSpamPatterns('THIS IS ALL CAPS AND ANNOYING'),
        'Merci de ne pas écrire tout en majuscules.',
      );
    });

    test('should allow normal all caps for short text', () {
      expect(
        TextValidator.validateSpamPatterns('OK'),
        null,
      );
      
      expect(
        TextValidator.validateSpamPatterns('YES'),
        null,
      );
    });

    test('should allow mixed case text', () {
      expect(
        TextValidator.validateSpamPatterns('Hello World, This is Normal Text'),
        null,
      );
    });

    test('should handle empty or null text', () {
      expect(TextValidator.validateSpamPatterns(null), null);
      expect(TextValidator.validateSpamPatterns(''), null);
      expect(TextValidator.validateSpamPatterns('   '), null);
    });
  });

  group('TextValidator - Comprehensive Validation', () {
    test('should validate text with all checks enabled', () {
      // Should fail on forbidden word
      expect(
        TextValidator.validateText('This is shit'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
      
      // Should fail on contact info
      expect(
        TextValidator.validateText('Contact me@example.com'),
        'Le partage d\'informations de contact n\'est pas autorisé.',
      );
      
      // Should fail on spam
      expect(
        TextValidator.validateText('YELLING IN ALL CAPS IS BAD'),
        'Merci de ne pas écrire tout en majuscules.',
      );
      
      // Should pass clean text
      expect(
        TextValidator.validateText('Hello, I enjoy hiking and cooking'),
        null,
      );
    });

    test('should respect validation flags', () {
      // Disable forbidden words check
      expect(
        TextValidator.validateText(
          'This is shit',
          checkForbiddenWords: false,
        ),
        null,
      );
      
      // Disable contact info check
      expect(
        TextValidator.validateText(
          'My email is test@example.com',
          checkContactInfo: false,
        ),
        null,
      );
      
      // Disable spam patterns check
      expect(
        TextValidator.validateText(
          'YELLING IN ALL CAPS',
          checkSpamPatterns: false,
        ),
        null,
      );
    });

    test('should handle empty or null text', () {
      expect(
        TextValidator.validateText(null),
        null,
      );
      
      expect(
        TextValidator.validateText(''),
        null,
      );
      
      expect(
        TextValidator.validateText('   '),
        null,
      );
    });
  });

  group('TextValidator - Text Normalization', () {
    test('should normalize accented characters', () {
      // Testing through forbidden words validation
      expect(
        TextValidator.validateForbiddenWords('putàin'),
        'Ce texte contient des mots interdits. Merci de rester respectueux.',
      );
    });

    test('should clean text properly', () {
      expect(
        TextValidator.cleanText('  Hello   World  '),
        'Hello World',
      );
      
      expect(
        TextValidator.cleanText('Multiple   spaces   here'),
        'Multiple spaces here',
      );
    });
  });
}
