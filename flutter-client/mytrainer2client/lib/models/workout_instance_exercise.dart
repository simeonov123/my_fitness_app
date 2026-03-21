import 'exercise.dart';
import 'workout_instance_exercise_set.dart';

class WorkoutInstanceExercise {
  final int id;
  final int workoutInstanceId;
  final int? clientId;
  final String? clientName;
  final Exercise exercise;
  int sequenceOrder;
  String? setType;
  String? setParams;
  int? restSeconds;
  String? notes;
  List<WorkoutInstanceExerciseSet> sets;

  WorkoutInstanceExercise({
    required this.id,
    required this.workoutInstanceId,
    this.clientId,
    this.clientName,
    required this.exercise,
    required this.sequenceOrder,
    this.setType,
    this.setParams,
    this.restSeconds,
    this.notes,
    List<WorkoutInstanceExerciseSet>? sets,
  }) : sets = sets ?? [];

  factory WorkoutInstanceExercise.fromJson(Map<String, dynamic> j) {
    final ex = Exercise(
      id: (j['exerciseId'] as num).toInt(),
      name: j['exerciseName'] as String? ?? '',
      isCustom: true,
      defaultSetType: j['exerciseDefaultSetType'] as String?,
      defaultSetParams: j['exerciseDefaultSetParams'] as String?,
    );

    final parentId = (j['id'] as num).toInt();
    return WorkoutInstanceExercise(
      id: parentId,
      workoutInstanceId: (j['workoutInstanceId'] as num).toInt(),
      clientId: (j['clientId'] as num?)?.toInt(),
      clientName: j['clientName'] as String?,
      exercise: ex,
      sequenceOrder: (j['sequenceOrder'] as num).toInt(),
      setType: j['setType'] as String?,
      setParams: j['setParams'] as String?,
      restSeconds: (j['restSeconds'] as num?)?.toInt(),
      notes: j['notes'] as String?,
      sets: (j['sets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map((m) => WorkoutInstanceExerciseSet.fromJson(
                m,
                workoutExerciseId: parentId,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutInstanceId': workoutInstanceId,
        'clientId': clientId,
        'clientName': clientName,
        'exerciseId': exercise.id,
        'sequenceOrder': sequenceOrder,
        'setType': setType,
        'setParams': setParams,
        'restSeconds': restSeconds,
        'notes': notes,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}
