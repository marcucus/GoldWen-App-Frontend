// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'GoldWen';

  @override
  String stepTitle(int step) {
    return 'Étape $step/6';
  }

  @override
  String get aboutYouTitle => 'Parlez-nous de vous';

  @override
  String get aboutYouSubtitle =>
      'Ces informations aideront les autres à mieux vous connaître';

  @override
  String get pseudoLabel => 'Pseudo';

  @override
  String get pseudoHint => 'Votre pseudo';

  @override
  String get pseudoRequired => 'Veuillez entrer votre pseudo';

  @override
  String get pseudoMinLength => 'Le pseudo doit contenir au moins 2 caractères';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bioHint => 'Décrivez-vous en quelques mots...';

  @override
  String get bioRequired => 'Veuillez rédiger votre bio';

  @override
  String bioMaxLength(int current) {
    return 'La bio dépasse la limite de 600 caractères ($current/600)';
  }

  @override
  String get continueButton => 'Continuer';

  @override
  String continueWithPhotos(int count) {
    return 'Continuer ($count/6)';
  }

  @override
  String continueMinPhotos(int count) {
    return 'Continuer ($count/3 minimum)';
  }

  @override
  String photosAddedCount(int count) {
    return '$count/3 photos minimum ajoutées';
  }

  @override
  String get photosMissing => 'Photos manquantes';

  @override
  String get understood => 'J\'ai compris';

  @override
  String get mediaOptionalTitle => 'Médias Audio/Vidéo (Optionnel)';

  @override
  String get mediaOptionalSubtitle =>
      'Ajoutez des fichiers audio ou vidéo pour enrichir votre profil';

  @override
  String get choosePromptsTitle => 'Choisissez vos prompts';

  @override
  String get choosePromptsSubtitle =>
      'Sélectionnez 3 questions qui vous représentent';

  @override
  String get promptLoadingError => 'Erreur lors du chargement des prompts';

  @override
  String get retry => 'Réessayer';

  @override
  String get promptAnswerHint => 'Votre réponse... (max 150 caractères)';

  @override
  String get promptRequired => 'Erreur: 3 prompts requis pour continuer';

  @override
  String promptAnswerRequired(int number) {
    return 'Veuillez répondre à la question $number';
  }

  @override
  String promptAnswerMaxLength(int number, int current) {
    return 'La réponse $number dépasse 150 caractères ($current/150)';
  }

  @override
  String get savingInProgress => 'Sauvegarde en cours...';

  @override
  String get startAdventure => 'Commencer mon aventure';

  @override
  String get profileIncompleteTitle => 'Profil incomplet';

  @override
  String get profileNotVisibleYet =>
      'Votre profil n\'est pas encore visible. Complétez toutes les étapes pour le rendre visible.';

  @override
  String get profileIncompleteSteps =>
      'Votre profil n\'est pas encore complet. Étapes manquantes:';

  @override
  String errorSaving(String error) {
    return 'Erreur lors de la sauvegarde: $error';
  }

  @override
  String errorSavingProfile(String error) {
    return 'Erreur lors de la sauvegarde du profil: $error';
  }

  @override
  String get pseudoRequiredError => 'Veuillez saisir votre pseudo';

  @override
  String get birthDateRequired =>
      'Veuillez sélectionner votre date de naissance';

  @override
  String get additionalInfoTitle => 'Informations complémentaires';

  @override
  String get shareMoreTitle => 'Partagez-en plus sur vous';

  @override
  String get shareMoreSubtitle =>
      'Ces informations sont optionnelles mais aident à créer des connexions plus profondes.';

  @override
  String get professionalInfoSection => 'Informations professionnelles';

  @override
  String get jobTitleLabel => 'Métier';

  @override
  String get jobTitleHint => 'Développeur, Designer, Médecin...';

  @override
  String get interestSport => 'Sport';

  @override
  String get interestTravel => 'Voyage';

  @override
  String get interestCooking => 'Cuisine';

  @override
  String get interestReading => 'Lecture';

  @override
  String get interestCinema => 'Cinéma';

  @override
  String get interestMusic => 'Musique';

  @override
  String get interestArt => 'Art';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestPhotography => 'Photographie';

  @override
  String get interestDance => 'Danse';

  @override
  String get interestTheater => 'Théâtre';

  @override
  String get interestFashion => 'Mode';

  @override
  String get interestTechnology => 'Technologie';

  @override
  String get interestAnimals => 'Animaux';

  @override
  String get interestGardening => 'Jardinage';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestRunning => 'Running';

  @override
  String get interestClimbing => 'Escalade';

  @override
  String get interestSurfing => 'Surf';

  @override
  String get interestSkiing => 'Ski';

  @override
  String get interestHiking => 'Randonnée';

  @override
  String get interestCycling => 'Vélo';

  @override
  String get interestMeditation => 'Méditation';

  @override
  String get interestSpirituality => 'Spiritualité';

  @override
  String get interestEntrepreneurship => 'Entrepreneuriat';

  @override
  String get interestVolunteering => 'Bénévolat';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get languageChinese => 'Chinois';

  @override
  String get languageJapanese => 'Japonais';

  @override
  String get languageRussian => 'Russe';

  @override
  String get languageDutch => 'Néerlandais';

  @override
  String get languageSwedish => 'Suédois';

  @override
  String get languageNorwegian => 'Norvégien';

  @override
  String get languageDanish => 'Danois';

  @override
  String get languagePolish => 'Polonais';

  @override
  String get languageCzech => 'Tchèque';

  @override
  String get languageHungarian => 'Hongrois';

  @override
  String get languageGreek => 'Grec';
}
