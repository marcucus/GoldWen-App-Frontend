// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GoldWen';

  @override
  String stepTitle(int step) {
    return 'Step $step/6';
  }

  @override
  String get aboutYouTitle => 'Tell us about yourself';

  @override
  String get aboutYouSubtitle =>
      'This information will help others get to know you better';

  @override
  String get pseudoLabel => 'Username';

  @override
  String get pseudoHint => 'Your username';

  @override
  String get pseudoRequired => 'Please enter your username';

  @override
  String get pseudoMinLength => 'Username must contain at least 2 characters';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bioHint => 'Describe yourself in a few words...';

  @override
  String get bioRequired => 'Please write your bio';

  @override
  String bioMaxLength(int current) {
    return 'Bio exceeds the 600 character limit ($current/600)';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String continueWithPhotos(int count) {
    return 'Continue ($count/6)';
  }

  @override
  String continueMinPhotos(int count) {
    return 'Continue ($count/3 minimum)';
  }

  @override
  String photosAddedCount(int count) {
    return '$count/3 minimum photos added';
  }

  @override
  String get photosMissing => 'Photos missing';

  @override
  String get understood => 'Understood';

  @override
  String get mediaOptionalTitle => 'Audio/Video Media (Optional)';

  @override
  String get mediaOptionalSubtitle =>
      'Add audio or video files to enrich your profile';

  @override
  String get choosePromptsTitle => 'Choose your prompts';

  @override
  String get choosePromptsSubtitle => 'Select 3 questions that represent you';

  @override
  String get promptLoadingError => 'Error loading prompts';

  @override
  String get retry => 'Retry';

  @override
  String get promptAnswerHint => 'Your answer... (max 150 characters)';

  @override
  String get promptRequired => 'Error: 3 prompts required to continue';

  @override
  String promptAnswerRequired(int number) {
    return 'Please answer question $number';
  }

  @override
  String promptAnswerMaxLength(int number, int current) {
    return 'Answer $number exceeds 150 characters ($current/150)';
  }

  @override
  String get savingInProgress => 'Saving in progress...';

  @override
  String get startAdventure => 'Start my adventure';

  @override
  String get profileIncompleteTitle => 'Incomplete profile';

  @override
  String get profileNotVisibleYet =>
      'Your profile is not yet visible. Complete all steps to make it visible.';

  @override
  String get profileIncompleteSteps =>
      'Your profile is not yet complete. Missing steps:';

  @override
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String errorSavingProfile(String error) {
    return 'Error saving profile: $error';
  }

  @override
  String get pseudoRequiredError => 'Please enter your username';

  @override
  String get birthDateRequired => 'Please select your birth date';

  @override
  String get additionalInfoTitle => 'Additional information';

  @override
  String get shareMoreTitle => 'Share more about yourself';

  @override
  String get shareMoreSubtitle =>
      'This information is optional but helps create deeper connections.';

  @override
  String get professionalInfoSection => 'Professional information';

  @override
  String get jobTitleLabel => 'Occupation';

  @override
  String get jobTitleHint => 'Developer, Designer, Doctor...';

  @override
  String get interestSport => 'Sport';

  @override
  String get interestTravel => 'Travel';

  @override
  String get interestCooking => 'Cooking';

  @override
  String get interestReading => 'Reading';

  @override
  String get interestCinema => 'Cinema';

  @override
  String get interestMusic => 'Music';

  @override
  String get interestArt => 'Art';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestPhotography => 'Photography';

  @override
  String get interestDance => 'Dance';

  @override
  String get interestTheater => 'Theater';

  @override
  String get interestFashion => 'Fashion';

  @override
  String get interestTechnology => 'Technology';

  @override
  String get interestAnimals => 'Animals';

  @override
  String get interestGardening => 'Gardening';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestRunning => 'Running';

  @override
  String get interestClimbing => 'Climbing';

  @override
  String get interestSurfing => 'Surfing';

  @override
  String get interestSkiing => 'Skiing';

  @override
  String get interestHiking => 'Hiking';

  @override
  String get interestCycling => 'Cycling';

  @override
  String get interestMeditation => 'Meditation';

  @override
  String get interestSpirituality => 'Spirituality';

  @override
  String get interestEntrepreneurship => 'Entrepreneurship';

  @override
  String get interestVolunteering => 'Volunteering';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageGerman => 'German';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageDutch => 'Dutch';

  @override
  String get languageSwedish => 'Swedish';

  @override
  String get languageNorwegian => 'Norwegian';

  @override
  String get languageDanish => 'Danish';

  @override
  String get languagePolish => 'Polish';

  @override
  String get languageCzech => 'Czech';

  @override
  String get languageHungarian => 'Hungarian';

  @override
  String get languageGreek => 'Greek';
}
