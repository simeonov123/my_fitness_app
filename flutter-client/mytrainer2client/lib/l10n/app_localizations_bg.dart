// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get brandTitle => 'MVFitness';

  @override
  String get tagline => 'Свържи се, тренирай и постигни целите си';

  @override
  String get description =>
      'Управлявай клиенти, тренировки, хранителни планове и обратна връзка на едно място в платформа с постижения и значки.';

  @override
  String get signInButton => 'Вход / Регистрация';

  @override
  String get learnMoreButton => 'Научи повече';

  @override
  String get localeToggleLabel => 'BG';

  @override
  String get authenticatingLabel => 'Свързване със защитения вход...';

  @override
  String get authFailedLabel => 'Възникна грешка.\nМоля, опитай отново.';

  @override
  String get tryAgainButton => 'Опитай отново';

  @override
  String get reorder_exercises => 'Пренареди упражненията';

  @override
  String get cancel => 'Отказ';

  @override
  String get save => 'Запази';

  @override
  String get delete => 'Изтрий';

  @override
  String get discard => 'Отхвърли';

  @override
  String set_number(Object number) {
    return 'Серия $number';
  }

  @override
  String get add_set => 'Добави серия';

  @override
  String get kg => 'кг';

  @override
  String get reps => 'повт.';

  @override
  String get time => 'време';

  @override
  String get km => 'км';

  @override
  String get weight_reps => 'Тежест + Повторения';

  @override
  String get bodyweight_reps => 'Собствено тегло + Повторения';

  @override
  String get weighted_bodyweight => 'Собствено тегло с тежест';

  @override
  String get assisted_bodyweight => 'Асистирано собствено тегло';

  @override
  String get duration => 'Продължителност';

  @override
  String get duration_weight => 'Време + Тежест';

  @override
  String get distance_duration => 'Разстояние + Време';

  @override
  String get weight_distance => 'Тежест + Разстояние';

  @override
  String get unknown => 'Непознат тип';

  @override
  String get unsaved_changes_title => 'Незаписани промени';

  @override
  String get unsaved_changes_body =>
      'Имаш незаписани промени. Какво искаш да направиш?';

  @override
  String get navHome => 'Начало';

  @override
  String get navWorkout => 'Тренировки';

  @override
  String get navSocial => 'Социално';

  @override
  String get navPrograms => 'Програми';

  @override
  String get navClients => 'Клиенти';

  @override
  String get navNutrition => 'Хранене';

  @override
  String comingSoonMessage(Object section) {
    return '$section предстои скоро';
  }

  @override
  String get calendarTitle => 'Календар';

  @override
  String get copyAccessTokenTooltip => 'Копирай токена за достъп';

  @override
  String get accessTokenCopied => 'Токенът за достъп е копиран';

  @override
  String get profileTooltip => 'Профил и настройки';

  @override
  String get todayLabel => 'Днес';

  @override
  String get tomorrowLabel => 'Утре';

  @override
  String get yesterdayLabel => 'Вчера';

  @override
  String get timelineHint =>
      'Докосни ден, за да прегледаш сесиите. Задръж върху ден, за да създадеш нова веднага.';

  @override
  String get newSessionLabel => 'Нова';

  @override
  String failedToCreateSession(Object error) {
    return 'Неуспешно създаване на сесия: $error';
  }

  @override
  String dailySummary(
      Object dayLabel, Object sessionsLabel, Object clientsLabel) {
    return '$dayLabel имаш $sessionsLabel с общо $clientsLabel.';
  }

  @override
  String get sessionCountOne => '1 сесия';

  @override
  String sessionCountMany(Object count) {
    return '$count сесии';
  }

  @override
  String get clientCountOne => '1 клиент';

  @override
  String clientCountMany(Object count) {
    return '$count клиента';
  }

  @override
  String get profileTitle => 'Профил';

  @override
  String get languageSectionTitle => 'Език';

  @override
  String get languageSystem => 'Използвай езика на устройството';

  @override
  String get languageEnglish => 'Английски';

  @override
  String get languageBulgarian => 'Български';

  @override
  String get logoutLabel => 'Изход';
}
