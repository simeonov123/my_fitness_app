import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get brandTitle => 'MVФитнес';

  @override
  String get tagline => 'Свържете се, тренирайте и покорете целите си';

  @override
  String get description => 'Управлявайте клиенти, тренировки, хранителни планове и обратна връзка—всичко в една фриймиум платформа с постижения и значки.';

  @override
  String get signInButton => 'Вход / Регистрация';

  @override
  String get learnMoreButton => 'Научете повече';

  @override
  String get localeToggleLabel => 'BG';

  @override
  String get authenticatingLabel => 'Зарежда страница със защитена форма за вписване в приложението…';

  @override
  String get authFailedLabel => 'Опаля – нещо се прецака.\nМоля опитайте отново.';

  @override
  String get tryAgainButton => 'Опитайте отново';

  @override
  String get reorder_exercises => 'Пренареди упражненията';

  @override
  String get cancel => 'Отказ';

  @override
  String get save => 'Запази';

  @override
  String get delete => 'Изтриване';

  @override
  String set_number(Object number) {
    return 'Серия $number';
  }

  @override
  String get add_set => 'Добави серия';

  @override
  String get kg => 'кг';

  @override
  String get reps => 'повт';

  @override
  String get time => 'време';

  @override
  String get km => 'км';

  @override
  String get weight_reps => 'Тежест + Повт';

  @override
  String get bodyweight_reps => 'Собствено тегло + Повт';

  @override
  String get weighted_bodyweight => 'Утежнено собствено тегло';

  @override
  String get assisted_bodyweight => 'Асистирано';

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
  String get unsaved_changes_body => 'Имате незаписани промени. Какво искате да направите?';

  @override
  String get discard => 'Отмени';
}
