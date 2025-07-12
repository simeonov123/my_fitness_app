import 'exercise.dart';
import 'workout_template_exercise_set.dart';

class WorkoutTemplateExercise {
  final int id;
  final Exercise exercise;
  int sequenceOrder;
  String? setType;
  String? setParams;
  String? notes;
  List<WorkoutTemplateExerciseSet> sets;

  WorkoutTemplateExercise({
    required this.id,
    required this.exercise,
    required this.sequenceOrder,
    this.setType,
    this.setParams,
    this.notes,
    List<WorkoutTemplateExerciseSet>? sets,
  }) : sets = sets ?? [];

  factory WorkoutTemplateExercise.fromJson(Map<String, dynamic> j) {
    // Pull in the exercise defaults from the new fields
    final ex = Exercise(
      id: (j['exerciseId'] as num).toInt(),
      name: j['exerciseName'] as String? ?? '',
      // `isCustom` is required; default to true here
      isCustom: true,
      defaultSetType: j['exerciseDefaultSetType'] as String?,
      defaultSetParams: j['exerciseDefaultSetParams'] as String?,
    );

    final parentId = (j['id'] as num).toInt();
    final rawSets = (j['sets'] as List<dynamic>?) ?? <dynamic>[];

    return WorkoutTemplateExercise(
      id: parentId,
      exercise: ex,
      sequenceOrder: (j['sequenceOrder'] as num).toInt(),
      setType: j['setType'] as String?,
      setParams: j['setParams'] as String?,
      notes: j['notes'] as String?,
      sets: rawSets
          .cast<Map<String, dynamic>>()
          .map((m) => WorkoutTemplateExerciseSet.fromJson(
        m,
        workoutExerciseId: parentId,
      ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exercise.id,
    'sequenceOrder': sequenceOrder,
    'setType': setType,
    'setParams': setParams,
    'notes': notes,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  /// param keys in order, falling back to exercise.defaultSetParams
  List<String> get paramKeys {
    final raw = setParams?.split(',') ??
        exercise.defaultSetParams?.split(',') ??
        <String>[];
    return raw
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }
}
