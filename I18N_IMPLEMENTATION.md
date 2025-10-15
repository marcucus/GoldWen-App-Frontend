# Internationalization (i18n) Implementation

## Overview

This document describes the i18n implementation for the GoldWen app, specifically addressing missing translations for step 4/6 (Prompts page) and other profile setup pages.

## Files Added

### Configuration
- `l10n.yaml` - Flutter localization configuration
- Updated `pubspec.yaml` with `generate: true`

### Translation Files (ARB)
- `lib/l10n/app_fr.arb` - French translations (default)
- `lib/l10n/app_en.arb` - English translations

### Helper Classes
- `lib/core/utils/translations_helper.dart` - Helper to provide translated lists of interests and languages

### Updated Files
- `lib/main.dart` - Added AppLocalizations delegate
- `lib/features/profile/pages/profile_setup_page.dart` - Updated to use l10n for all text
- `lib/features/onboarding/pages/additional_info_page.dart` - Updated to use l10n for interests and languages

## Translations Covered

### Step 4/6 - Prompts Page
- ✅ "Choisissez vos prompts" / "Choose your prompts"
- ✅ "Sélectionnez 3 questions qui vous représentent" 
- ✅ "Votre réponse... (max 150 caractères)"
- ✅ Error messages for prompts
- ✅ "Erreur lors du chargement des prompts"
- ✅ "Réessayer" / "Retry"

### Other Profile Setup Pages
- ✅ Step indicator: "Étape X/6" / "Step X/6"
- ✅ Basic info page (page 1/6)
- ✅ Photos page (page 2/6)
- ✅ Media page (page 3/6)
- ✅ Validation messages
- ✅ Error messages

### Additional Info Page
- ✅ All 28 interests (Sport, Voyage, Cuisine, etc.)
- ✅ All 18 languages (Français, Anglais, Espagnol, etc.)
- ✅ Section titles and labels

## How to Build

1. **Generate localization files:**
   ```bash
   flutter gen-l10n
   ```
   
   This will generate the `AppLocalizations` class in `.dart_tool/flutter_gen/gen_l10n/`

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Build the app:**
   ```bash
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```

## Generated Files (Auto-generated, not committed)

The following files will be auto-generated when you run `flutter gen-l10n`:
- `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
- `.dart_tool/flutter_gen/gen_l10n/app_localizations_fr.dart`
- `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`

These files are excluded from git via `.gitignore`.

## Usage in Code

### Simple text:
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.continueButton)  // "Continuer" in French, "Continue" in English
```

### Text with parameters:
```dart
Text(l10n.stepTitle(4))  // "Étape 4/6" in French, "Step 4/6" in English
Text(l10n.bioMaxLength(650))  // "La bio dépasse la limite de 600 caractères (650/600)"
```

### Lists (Interests/Languages):
```dart
final interests = TranslationsHelper.getAvailableInterests(context);
final languages = TranslationsHelper.getAvailableLanguages(context);
```

## Supported Locales

- French (fr) - Default
- English (en)

## Adding New Translations

1. Add the key and translation to `lib/l10n/app_fr.arb`:
   ```json
   "myNewKey": "Ma nouvelle traduction",
   "@myNewKey": {
     "description": "Description of this translation"
   }
   ```

2. Add the English version to `lib/l10n/app_en.arb`:
   ```json
   "myNewKey": "My new translation"
   ```

3. Run `flutter gen-l10n` to regenerate the AppLocalizations class

4. Use in code:
   ```dart
   Text(l10n.myNewKey)
   ```

## Testing

To verify translations work correctly:

1. Ensure you've run `flutter gen-l10n`
2. Run the app in French (default)
3. Change device language to English to see English translations
4. Verify that step 4/6 (Prompts page) displays all text in the selected language

## Notes

- All hardcoded French strings in step 4/6 have been replaced with i18n keys
- Interests and languages are now translated
- Error messages are now translatable
- The implementation follows Flutter's official i18n guidelines
