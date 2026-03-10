class WorkoutInstanceExerciseSet {
  int id;                    // db PK
  int workoutExerciseId;     // parent FK
  int setNumber;             // 1-based
  bool completed;
  Map<String, double> values;

  WorkoutInstanceExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.completed = false,
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
        completed: j['completed'] as bool? ?? false,
        values: {
          for (final m in (j['data'] as List<dynamic>? ?? []))
            (m['type'] as String): (m['value'] as num).toDouble()
        },
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutExerciseId': workoutExerciseId,
    'setNumber': setNumber,
    'completed': completed,
    'data': values.entries
        .map((e) => {'type': e.key, 'value': e.value})
        .toList(),
  };
}
