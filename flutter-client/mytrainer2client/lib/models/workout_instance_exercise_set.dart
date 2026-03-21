class WorkoutInstanceExerciseSet {
  int id; // db PK
  int workoutExerciseId; // parent FK
  int setNumber; // 1-based
  bool completed;
  String? setContextType;
  String? notes;
  int? stopwatchStartedAtMs;
  int? restStartedAtMs;
  Map<String, double> values;

  WorkoutInstanceExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.completed = false,
    this.setContextType,
    this.notes,
    this.stopwatchStartedAtMs,
    this.restStartedAtMs,
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
        stopwatchStartedAtMs: (j['stopwatchStartedAtMs'] as num?)?.toInt(),
        restStartedAtMs: (j['restStartedAtMs'] as num?)?.toInt(),
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
        'stopwatchStartedAtMs': stopwatchStartedAtMs,
        'restStartedAtMs': restStartedAtMs,
        'data': values.entries
            .map((e) => {'type': e.key, 'value': e.value})
            .toList(),
      };
}
