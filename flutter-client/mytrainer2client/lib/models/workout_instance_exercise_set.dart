class WorkoutInstanceExerciseSet {
  int id;                    // db PK
  int workoutExerciseId;     // parent FK
  int setNumber;             // 1-based
  Map<String, double> values;

  WorkoutInstanceExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    Map<String, double>? values,
  }) : values = values ?? {};

  /* ─── json ─── */
  factory WorkoutInstanceExerciseSet.fromJson(
      Map<String, dynamic> j, {
        required int workoutExerciseId,
      }) =>
      WorkoutInstanceExerciseSet(
        id: (j['id'] as num).toInt(),
        workoutExerciseId: workoutExerciseId,
        setNumber: (j['setNumber'] as num).toInt(),
        values: {
          for (final m in (j['data'] as List<dynamic>? ?? []))
            (m['type'] as String): (m['value'] as num).toDouble()
        },
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutExerciseId': workoutExerciseId,
    'setNumber': setNumber,
    'data': values.entries
        .map((e) => {'type': e.key, 'value': e.value})
        .toList(),
  };
}
