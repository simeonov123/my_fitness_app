// lib/models/workout_template_exercise_set.dart

class WorkoutTemplateExerciseSet {
  int id;                  // 0 = not yet persisted
  int workoutExerciseId;   // now passed in by the caller
  int setNumber;           // 1,2,3,...
  Map<String, double> values;

  WorkoutTemplateExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    required this.values,
  });

  WorkoutTemplateExerciseSet copyWith({
    int? id,
    int? workoutExerciseId,
    int? setNumber,
    Map<String, double>? values,
  }) =>
      WorkoutTemplateExerciseSet(
        id: id ?? this.id,
        workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
        setNumber: setNumber ?? this.setNumber,
        values: values ?? Map.from(this.values),
      );

  /// now requires the parent WTE id
  factory WorkoutTemplateExerciseSet.fromJson(
      Map<String, dynamic> j, {
        required int workoutExerciseId,
      }) {
    final dataList = (j['data'] as List<dynamic>?) ?? <dynamic>[];
    return WorkoutTemplateExerciseSet(
      id: (j['id'] as num).toInt(),
      workoutExerciseId: workoutExerciseId,
      setNumber: (j['setNumber'] as num).toInt(),
      values: {
        for (final item in dataList.cast<Map<String, dynamic>>())
          (item['type'] as String): (item['value'] as num).toDouble(),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutExerciseId': workoutExerciseId,
    'setNumber': setNumber,
    'data': values.entries
        .map((e) => {'type': e.key, 'value': e.value})
        .toList(),
  };
}
