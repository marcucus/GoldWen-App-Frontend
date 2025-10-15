/// Text validation utilities for input sanitization
/// 
/// This utility provides validation functions for user-generated content
/// including forbidden words detection and content filtering.
class TextValidator {
  // List of forbidden words/phrases (extensible)
  // Note: This is a frontend validation. Backend should also validate.
  static final List<String> _forbiddenWords = [
    // Explicit content
    'fuck',
    'shit',
    'bitch',
    'ass',
    'dick',
    'cock',
    'pussy',
    'cunt',
    'bastard',
    'damn',
    // Hate speech
    'nazi',
    'nigger',
    'faggot',
    'retard',
    // Scam/Spam related
    'crypto',
    'bitcoin',
    'forex',
    'investment',
    'whatsapp',
    'telegram',
    'onlyfans',
    'cashapp',
    'venmo',
    'paypal',
    // Contact info patterns
    'instagram',
    'snapchat',
    'facebook',
    'tiktok',
    // French profanity
    'putain',
    'merde',
    'connard',
    'connasse',
    'salope',
    'enculé',
    'bite',
    'chatte',
    'con',
    'conne',
    'pute',
  ];

  /// Validates text for forbidden words
  /// Returns null if valid, error message if invalid
  static String? validateForbiddenWords(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null; // Empty text is handled by other validators
    }

    final normalizedText = _normalizeText(text);
    
    for (final word in _forbiddenWords) {
      // Check for whole word match with word boundaries
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(normalizedText)) {
        return 'Ce texte contient des mots interdits. Merci de rester respectueux.';
      }
    }

    return null; // Text is valid
  }

  /// Validates text for contact information patterns
  static String? validateContactInfo(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final normalizedText = _normalizeText(text);

    // Email pattern
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
        .hasMatch(normalizedText)) {
      return 'Le partage d\'informations de contact n\'est pas autorisé.';
    }

    // Phone number pattern (various formats)
    if (RegExp(r'\b(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{2,4}[-.\s]?\d{2,4}[-.\s]?\d{0,4}\b')
        .hasMatch(normalizedText)) {
      return 'Le partage de numéros de téléphone n\'est pas autorisé.';
    }

    // URL pattern
    if (RegExp(r'https?://|www\.|\.com|\.fr|\.net|\.org', caseSensitive: false)
        .hasMatch(normalizedText)) {
      return 'Le partage de liens n\'est pas autorisé.';
    }

    return null;
  }

  /// Validates text for spam patterns
  static String? validateSpamPatterns(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final normalizedText = _normalizeText(text);

    // Excessive repetition
    if (RegExp(r'(.)\1{4,}').hasMatch(normalizedText)) {
      return 'Merci d\'éviter les répétitions excessives.';
    }

    // All caps (for texts longer than 10 chars)
    if (normalizedText.length > 10 && normalizedText == normalizedText.toUpperCase()) {
      if (RegExp(r'[A-Z]').hasMatch(normalizedText)) {
        return 'Merci de ne pas écrire tout en majuscules.';
      }
    }

    return null;
  }

  /// Comprehensive validation combining all checks
  static String? validateText(String? text, {
    bool checkForbiddenWords = true,
    bool checkContactInfo = true,
    bool checkSpamPatterns = true,
  }) {
    if (text == null || text.trim().isEmpty) {
      return null; // Empty text validation should be handled separately
    }

    String? error;

    if (checkForbiddenWords) {
      error = validateForbiddenWords(text);
      if (error != null) return error;
    }

    if (checkContactInfo) {
      error = validateContactInfo(text);
      if (error != null) return error;
    }

    if (checkSpamPatterns) {
      error = validateSpamPatterns(text);
      if (error != null) return error;
    }

    return null;
  }

  /// Normalizes text for comparison (removes special chars, extra spaces)
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        // Replace common letter substitutions
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll('ç', 'c')
        // Replace leetspeak and number substitutions
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('@', 'a')
        .replaceAll('\$', 's')
        // Remove special characters except spaces and letters
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        // Normalize spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if text contains only valid characters
  static bool hasValidCharacters(String text) {
    // Allow letters, numbers, common punctuation, and emojis
    return RegExp(r'^[\w\s\p{L}\p{N}\p{P}\p{S}\p{Emoji}]+$', unicode: true)
        .hasMatch(text);
  }

  /// Gets a cleaned version of text (removes extra spaces, trims)
  static String cleanText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
