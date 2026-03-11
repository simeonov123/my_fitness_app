class WorkoutInstanceExerciseSet {
  int id;                    // db PK
  int workoutExerciseId;     // parent FK
  int setNumber;             // 1-based
  bool completed;
  String? setContextType;
  String? notes;
  Map<String, double> values;

  WorkoutInstanceExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.completed = false,
    this.setContextType,
    this.notes,
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
        setContextType: j['setContextType'] as String?,
        notes: j['notes'] as String?,
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
    'setContextType': setContextType,
    'notes': notes,
    'data': values.entries
        .map((e) => {'type': e.key, 'value': e.value})
        .toList(),
  };
}
