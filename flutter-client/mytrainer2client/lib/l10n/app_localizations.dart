import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bg'),
    Locale('en')
  ];

  /// No description provided for @brandTitle.
  ///
  /// In en, this message translates to:
  /// **'MVFitness'**
  String get brandTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Connect, Coach, and Conquer Your Goals'**
  String get tagline;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Manage clients, workouts, nutrition plans, and feedback—all in one freemium platform powered by achievements and badges.'**
  String get description;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In / Sign Up'**
  String get signInButton;

  /// No description provided for @learnMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMoreButton;

  /// No description provided for @localeToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get localeToggleLabel;

  /// No description provided for @authenticatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Contacting secure login…'**
  String get authenticatingLabel;

  /// No description provided for @authFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Oops – something went wrong.\nPlease try again.'**
  String get authFailedLabel;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @reorder_exercises.
  ///
  /// In en, this message translates to:
  /// **'Reorder Exercises'**
  String get reorder_exercises;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for a specific set number, e.g. “Set 1”
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String set_number(Object number);

  /// No description provided for @add_set.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get add_set;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get reps;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get time;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @weight_reps.
  ///
  /// In en, this message translates to:
  /// **'Weight + Reps'**
  String get weight_reps;

  /// No description provided for @bodyweight_reps.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight + Reps'**
  String get bodyweight_reps;

  /// No description provided for @weighted_bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Weighted Bodyweight'**
  String get weighted_bodyweight;

  /// No description provided for @assisted_bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Assisted Bodyweight'**
  String get assisted_bodyweight;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @duration_weight.
  ///
  /// In en, this message translates to:
  /// **'Duration + Weight'**
  String get duration_weight;

  /// No description provided for @distance_duration.
  ///
  /// In en, this message translates to:
  /// **'Distance + Duration'**
  String get distance_duration;

  /// No description provided for @weight_distance.
  ///
  /// In en, this message translates to:
  /// **'Weight + Distance'**
  String get weight_distance;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get unknown;

  /// No description provided for @unsaved_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsaved_changes_title;

  /// No description provided for @unsaved_changes_body.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get unsaved_changes_body;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bg', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg': return AppLocalizationsBg();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
