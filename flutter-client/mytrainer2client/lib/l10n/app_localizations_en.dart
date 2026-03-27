// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandTitle => 'MVFitness';

  @override
  String get tagline => 'Connect, Coach, and Conquer Your Goals';

  @override
  String get description =>
      'Manage clients, workouts, nutrition plans, and feedback all in one freemium platform powered by achievements and badges.';

  @override
  String get signInButton => 'Sign In / Sign Up';

  @override
  String get learnMoreButton => 'Learn More';

  @override
  String get localeToggleLabel => 'EN';

  @override
  String get authenticatingLabel => 'Contacting secure login...';

  @override
  String get authFailedLabel =>
      'Oops - something went wrong.\nPlease try again.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get reorder_exercises => 'Reorder Exercises';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String set_number(Object number) {
    return 'Set $number';
  }

  @override
  String get add_set => 'Add set';

  @override
  String get kg => 'kg';

  @override
  String get reps => 'reps';

  @override
  String get time => 'time';

  @override
  String get km => 'km';

  @override
  String get weight_reps => 'Weight + Reps';

  @override
  String get bodyweight_reps => 'Bodyweight + Reps';

  @override
  String get weighted_bodyweight => 'Weighted Bodyweight';

  @override
  String get assisted_bodyweight => 'Assisted Bodyweight';

  @override
  String get duration => 'Duration';

  @override
  String get duration_weight => 'Duration + Weight';

  @override
  String get distance_duration => 'Distance + Duration';

  @override
  String get weight_distance => 'Weight + Distance';

  @override
  String get unknown => 'Unknown type';

  @override
  String get unsaved_changes_title => 'Unsaved changes';

  @override
  String get unsaved_changes_body =>
      'You have unsaved changes. What would you like to do?';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navSocial => 'Social';

  @override
  String get navPrograms => 'Programs';

  @override
  String get navClients => 'Clients';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String comingSoonMessage(Object section) {
    return '$section is coming soon';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get copyAccessTokenTooltip => 'Copy access token';

  @override
  String get accessTokenCopied => 'Access token copied';

  @override
  String get profileTooltip => 'Profile and settings';

  @override
  String get todayLabel => 'Today';

  @override
  String get tomorrowLabel => 'Tomorrow';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get timelineHint =>
      'Tap a day to review sessions. Press and hold a day to create one immediately.';

  @override
  String get newSessionLabel => 'New';

  @override
  String failedToCreateSession(Object error) {
    return 'Failed to create session: $error';
  }

  @override
  String dailySummary(
      Object dayLabel, Object sessionsLabel, Object clientsLabel) {
    return '$dayLabel you have $sessionsLabel with a total of $clientsLabel.';
  }

  @override
  String get sessionCountOne => '1 session';

  @override
  String sessionCountMany(Object count) {
    return '$count sessions';
  }

  @override
  String get clientCountOne => '1 client';

  @override
  String clientCountMany(Object count) {
    return '$count clients';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystem => 'Use system language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBulgarian => 'Bulgarian';

  @override
  String get logoutLabel => 'Log out';
}
