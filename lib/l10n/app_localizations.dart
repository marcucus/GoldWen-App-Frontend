import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The title of the application
  ///
  /// In fr, this message translates to:
  /// **'GoldWen'**
  String get appTitle;

  /// Step indicator in profile setup
  ///
  /// In fr, this message translates to:
  /// **'Étape {step}/6'**
  String stepTitle(int step);

  /// Title for basic info page
  ///
  /// In fr, this message translates to:
  /// **'Parlez-nous de vous'**
  String get aboutYouTitle;

  /// Subtitle for basic info page
  ///
  /// In fr, this message translates to:
  /// **'Ces informations aideront les autres à mieux vous connaître'**
  String get aboutYouSubtitle;

  /// Label for pseudo field
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get pseudoLabel;

  /// Hint for pseudo field
  ///
  /// In fr, this message translates to:
  /// **'Votre pseudo'**
  String get pseudoHint;

  /// Error message when pseudo is empty
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre pseudo'**
  String get pseudoRequired;

  /// Error message when pseudo is too short
  ///
  /// In fr, this message translates to:
  /// **'Le pseudo doit contenir au moins 2 caractères'**
  String get pseudoMinLength;

  /// Label for bio field
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// Hint for bio field
  ///
  /// In fr, this message translates to:
  /// **'Décrivez-vous en quelques mots...'**
  String get bioHint;

  /// Error message when bio is empty
  ///
  /// In fr, this message translates to:
  /// **'Veuillez rédiger votre bio'**
  String get bioRequired;

  /// Error message when bio exceeds max length
  ///
  /// In fr, this message translates to:
  /// **'La bio dépasse la limite de 600 caractères ({current}/600)'**
  String bioMaxLength(int current);

  /// Continue button text
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// Continue button with photo count
  ///
  /// In fr, this message translates to:
  /// **'Continuer ({count}/6)'**
  String continueWithPhotos(int count);

  /// Continue button with minimum photo count
  ///
  /// In fr, this message translates to:
  /// **'Continuer ({count}/3 minimum)'**
  String continueMinPhotos(int count);

  /// Photo count indicator
  ///
  /// In fr, this message translates to:
  /// **'{count}/3 photos minimum ajoutées'**
  String photosAddedCount(int count);

  /// Title for photo missing alert
  ///
  /// In fr, this message translates to:
  /// **'Photos manquantes'**
  String get photosMissing;

  /// Button text for understanding
  ///
  /// In fr, this message translates to:
  /// **'J\'ai compris'**
  String get understood;

  /// Title for media page
  ///
  /// In fr, this message translates to:
  /// **'Médias Audio/Vidéo (Optionnel)'**
  String get mediaOptionalTitle;

  /// Subtitle for media page
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des fichiers audio ou vidéo pour enrichir votre profil'**
  String get mediaOptionalSubtitle;

  /// Title for prompt selection
  ///
  /// In fr, this message translates to:
  /// **'Choisissez vos prompts'**
  String get choosePromptsTitle;

  /// Subtitle for prompt selection
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez 3 questions qui vous représentent'**
  String get choosePromptsSubtitle;

  /// Error message when prompts fail to load
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des prompts'**
  String get promptLoadingError;

  /// Retry button text
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Hint for prompt answer field
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse... (max 150 caractères)'**
  String get promptAnswerHint;

  /// Error when not all prompts are selected
  ///
  /// In fr, this message translates to:
  /// **'Erreur: 3 prompts requis pour continuer'**
  String get promptRequired;

  /// Error when prompt answer is empty
  ///
  /// In fr, this message translates to:
  /// **'Veuillez répondre à la question {number}'**
  String promptAnswerRequired(int number);

  /// Error when prompt answer exceeds max length
  ///
  /// In fr, this message translates to:
  /// **'La réponse {number} dépasse 150 caractères ({current}/150)'**
  String promptAnswerMaxLength(int number, int current);

  /// Text shown while saving
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde en cours...'**
  String get savingInProgress;

  /// Button to start using the app
  ///
  /// In fr, this message translates to:
  /// **'Commencer mon aventure'**
  String get startAdventure;

  /// Title for incomplete profile dialog
  ///
  /// In fr, this message translates to:
  /// **'Profil incomplet'**
  String get profileIncompleteTitle;

  /// Message when profile is not complete
  ///
  /// In fr, this message translates to:
  /// **'Votre profil n\'est pas encore visible. Complétez toutes les étapes pour le rendre visible.'**
  String get profileNotVisibleYet;

  /// Message listing incomplete steps
  ///
  /// In fr, this message translates to:
  /// **'Votre profil n\'est pas encore complet. Étapes manquantes:'**
  String get profileIncompleteSteps;

  /// Error message when save fails
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde: {error}'**
  String errorSaving(String error);

  /// Error message when profile save fails
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde du profil: {error}'**
  String errorSavingProfile(String error);

  /// Snackbar error for missing pseudo
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre pseudo'**
  String get pseudoRequiredError;

  /// Snackbar error for missing birth date
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner votre date de naissance'**
  String get birthDateRequired;

  /// Title for additional info page
  ///
  /// In fr, this message translates to:
  /// **'Informations complémentaires'**
  String get additionalInfoTitle;

  /// Title for additional info section
  ///
  /// In fr, this message translates to:
  /// **'Partagez-en plus sur vous'**
  String get shareMoreTitle;

  /// Subtitle for additional info section
  ///
  /// In fr, this message translates to:
  /// **'Ces informations sont optionnelles mais aident à créer des connexions plus profondes.'**
  String get shareMoreSubtitle;

  /// Section title for professional info
  ///
  /// In fr, this message translates to:
  /// **'Informations professionnelles'**
  String get professionalInfoSection;

  /// Label for job title field
  ///
  /// In fr, this message translates to:
  /// **'Métier'**
  String get jobTitleLabel;

  /// Hint for job title field
  ///
  /// In fr, this message translates to:
  /// **'Développeur, Designer, Médecin...'**
  String get jobTitleHint;

  /// Interest: Sport
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get interestSport;

  /// Interest: Travel
  ///
  /// In fr, this message translates to:
  /// **'Voyage'**
  String get interestTravel;

  /// Interest: Cooking
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get interestCooking;

  /// Interest: Reading
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get interestReading;

  /// Interest: Cinema
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get interestCinema;

  /// Interest: Music
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get interestMusic;

  /// Interest: Art
  ///
  /// In fr, this message translates to:
  /// **'Art'**
  String get interestArt;

  /// Interest: Nature
  ///
  /// In fr, this message translates to:
  /// **'Nature'**
  String get interestNature;

  /// Interest: Fitness
  ///
  /// In fr, this message translates to:
  /// **'Fitness'**
  String get interestFitness;

  /// Interest: Gaming
  ///
  /// In fr, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// Interest: Photography
  ///
  /// In fr, this message translates to:
  /// **'Photographie'**
  String get interestPhotography;

  /// Interest: Dance
  ///
  /// In fr, this message translates to:
  /// **'Danse'**
  String get interestDance;

  /// Interest: Theater
  ///
  /// In fr, this message translates to:
  /// **'Théâtre'**
  String get interestTheater;

  /// Interest: Fashion
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get interestFashion;

  /// Interest: Technology
  ///
  /// In fr, this message translates to:
  /// **'Technologie'**
  String get interestTechnology;

  /// Interest: Animals
  ///
  /// In fr, this message translates to:
  /// **'Animaux'**
  String get interestAnimals;

  /// Interest: Gardening
  ///
  /// In fr, this message translates to:
  /// **'Jardinage'**
  String get interestGardening;

  /// Interest: Yoga
  ///
  /// In fr, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// Interest: Running
  ///
  /// In fr, this message translates to:
  /// **'Running'**
  String get interestRunning;

  /// Interest: Climbing
  ///
  /// In fr, this message translates to:
  /// **'Escalade'**
  String get interestClimbing;

  /// Interest: Surfing
  ///
  /// In fr, this message translates to:
  /// **'Surf'**
  String get interestSurfing;

  /// Interest: Skiing
  ///
  /// In fr, this message translates to:
  /// **'Ski'**
  String get interestSkiing;

  /// Interest: Hiking
  ///
  /// In fr, this message translates to:
  /// **'Randonnée'**
  String get interestHiking;

  /// Interest: Cycling
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get interestCycling;

  /// Interest: Meditation
  ///
  /// In fr, this message translates to:
  /// **'Méditation'**
  String get interestMeditation;

  /// Interest: Spirituality
  ///
  /// In fr, this message translates to:
  /// **'Spiritualité'**
  String get interestSpirituality;

  /// Interest: Entrepreneurship
  ///
  /// In fr, this message translates to:
  /// **'Entrepreneuriat'**
  String get interestEntrepreneurship;

  /// Interest: Volunteering
  ///
  /// In fr, this message translates to:
  /// **'Bénévolat'**
  String get interestVolunteering;

  /// Language: French
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Language: English
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageEnglish;

  /// Language: Spanish
  ///
  /// In fr, this message translates to:
  /// **'Espagnol'**
  String get languageSpanish;

  /// Language: Italian
  ///
  /// In fr, this message translates to:
  /// **'Italien'**
  String get languageItalian;

  /// Language: German
  ///
  /// In fr, this message translates to:
  /// **'Allemand'**
  String get languageGerman;

  /// Language: Portuguese
  ///
  /// In fr, this message translates to:
  /// **'Portugais'**
  String get languagePortuguese;

  /// Language: Arabic
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get languageArabic;

  /// Language: Chinese
  ///
  /// In fr, this message translates to:
  /// **'Chinois'**
  String get languageChinese;

  /// Language: Japanese
  ///
  /// In fr, this message translates to:
  /// **'Japonais'**
  String get languageJapanese;

  /// Language: Russian
  ///
  /// In fr, this message translates to:
  /// **'Russe'**
  String get languageRussian;

  /// Language: Dutch
  ///
  /// In fr, this message translates to:
  /// **'Néerlandais'**
  String get languageDutch;

  /// Language: Swedish
  ///
  /// In fr, this message translates to:
  /// **'Suédois'**
  String get languageSwedish;

  /// Language: Norwegian
  ///
  /// In fr, this message translates to:
  /// **'Norvégien'**
  String get languageNorwegian;

  /// Language: Danish
  ///
  /// In fr, this message translates to:
  /// **'Danois'**
  String get languageDanish;

  /// Language: Polish
  ///
  /// In fr, this message translates to:
  /// **'Polonais'**
  String get languagePolish;

  /// Language: Czech
  ///
  /// In fr, this message translates to:
  /// **'Tchèque'**
  String get languageCzech;

  /// Language: Hungarian
  ///
  /// In fr, this message translates to:
  /// **'Hongrois'**
  String get languageHungarian;

  /// Language: Greek
  ///
  /// In fr, this message translates to:
  /// **'Grec'**
  String get languageGreek;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
