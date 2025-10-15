import 'package:flutter/material.dart';
import 'package:goldwen_app/l10n/app_localizations.dart';

/// Helper class to provide translated lists of interests and languages
class TranslationsHelper {
  /// Get translated list of available interests
  static List<String> getAvailableInterests(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.interestSport,
      l10n.interestTravel,
      l10n.interestCooking,
      l10n.interestReading,
      l10n.interestCinema,
      l10n.interestMusic,
      l10n.interestArt,
      l10n.interestNature,
      l10n.interestFitness,
      l10n.interestGaming,
      l10n.interestPhotography,
      l10n.interestDance,
      l10n.interestTheater,
      l10n.interestFashion,
      l10n.interestTechnology,
      l10n.interestAnimals,
      l10n.interestGardening,
      l10n.interestYoga,
      l10n.interestRunning,
      l10n.interestClimbing,
      l10n.interestSurfing,
      l10n.interestSkiing,
      l10n.interestHiking,
      l10n.interestCycling,
      l10n.interestMeditation,
      l10n.interestSpirituality,
      l10n.interestEntrepreneurship,
      l10n.interestVolunteering,
    ];
  }

  /// Get translated list of available languages
  static List<String> getAvailableLanguages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.languageFrench,
      l10n.languageEnglish,
      l10n.languageSpanish,
      l10n.languageItalian,
      l10n.languageGerman,
      l10n.languagePortuguese,
      l10n.languageArabic,
      l10n.languageChinese,
      l10n.languageJapanese,
      l10n.languageRussian,
      l10n.languageDutch,
      l10n.languageSwedish,
      l10n.languageNorwegian,
      l10n.languageDanish,
      l10n.languagePolish,
      l10n.languageCzech,
      l10n.languageHungarian,
      l10n.languageGreek,
    ];
  }
}
