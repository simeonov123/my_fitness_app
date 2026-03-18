import 'workout_instance_exercise_set.dart';

class ExerciseHistory {
  final int clientId;
  final String? clientName;
  final int exerciseId;
  final String exerciseName;
  final String? setType;
  final String? setParams;
  final ExerciseHistorySummary summary;
  final List<ExerciseHistorySnapshot> snapshots;

  ExerciseHistory({
    required this.clientId,
    required this.clientName,
    required this.exerciseId,
    required this.exerciseName,
    this.setType,
    this.setParams,
    required this.summary,
    required this.snapshots,
  });

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) {
    return ExerciseHistory(
      clientId: (json['clientId'] as num).toInt(),
      clientName: json['clientName'] as String?,
      exerciseId: (json['exerciseId'] as num).toInt(),
      exerciseName: json['exerciseName'] as String? ?? '',
      setType: json['setType'] as String?,
      setParams: json['setParams'] as String?,
      summary: ExerciseHistorySummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
      ),
      snapshots: (json['snapshots'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ExerciseHistorySnapshot.fromJson)
          .toList(),
    );
  }
}

class ExerciseHistorySummary {
  final double? averageBestRepsPerSet;
  final double? estimatedOneRepMax;
  final double? bestSetVolume;
  final double? bestWeight;
  final double? bestDurationSeconds;
  final double? bestDistanceKm;
  final double? fastestPaceSecondsPerKm;
  final List<String> supportedMetrics;

  ExerciseHistorySummary({
    this.averageBestRepsPerSet,
    this.estimatedOneRepMax,
    this.bestSetVolume,
    this.bestWeight,
    this.bestDurationSeconds,
    this.bestDistanceKm,
    this.fastestPaceSecondsPerKm,
    List<String>? supportedMetrics,
  }) : supportedMetrics = supportedMetrics ?? const [];

  factory ExerciseHistorySummary.fromJson(Map<String, dynamic> json) {
    return ExerciseHistorySummary(
      averageBestRepsPerSet:
          (json['averageBestRepsPerSet'] as num?)?.toDouble(),
      estimatedOneRepMax: (json['estimatedOneRepMax'] as num?)?.toDouble(),
      bestSetVolume: (json['bestSetVolume'] as num?)?.toDouble(),
      bestWeight: (json['bestWeight'] as num?)?.toDouble(),
      bestDurationSeconds: (json['bestDurationSeconds'] as num?)?.toDouble(),
      bestDistanceKm: (json['bestDistanceKm'] as num?)?.toDouble(),
      fastestPaceSecondsPerKm:
          (json['fastestPaceSecondsPerKm'] as num?)?.toDouble(),
      supportedMetrics: (json['supportedMetrics'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ExerciseHistorySnapshot {
  final int sessionId;
  final String? sessionName;
  final DateTime? sessionStart;
  final int workoutInstanceId;
  final int workoutInstanceExerciseId;
  final String? setType;
  final String? setParams;
  final int completedSetCount;
  final int totalSetCount;
  final double? bestReps;
  final double? estimatedOneRepMax;
  final double? bestSetVolume;
  final double? bestWeight;
  final double? bestDurationSeconds;
  final double? bestDistanceKm;
  final List<WorkoutInstanceExerciseSet> sets;

  ExerciseHistorySnapshot({
    required this.sessionId,
    this.sessionName,
    this.sessionStart,
    required this.workoutInstanceId,
    required this.workoutInstanceExerciseId,
    this.setType,
    this.setParams,
    required this.completedSetCount,
    required this.totalSetCount,
    this.bestReps,
    this.estimatedOneRepMax,
    this.bestSetVolume,
    this.bestWeight,
    this.bestDurationSeconds,
    this.bestDistanceKm,
    List<WorkoutInstanceExerciseSet>? sets,
  }) : sets = sets ?? const [];

  factory ExerciseHistorySnapshot.fromJson(Map<String, dynamic> json) {
    final parentId = (json['workoutInstanceExerciseId'] as num).toInt();
    return ExerciseHistorySnapshot(
      sessionId: (json['sessionId'] as num).toInt(),
      sessionName: json['sessionName'] as String?,
      sessionStart: json['sessionStart'] == null
          ? null
          : DateTime.tryParse(json['sessionStart'] as String),
      workoutInstanceId: (json['workoutInstanceId'] as num).toInt(),
      workoutInstanceExerciseId:
          (json['workoutInstanceExerciseId'] as num).toInt(),
      setType: json['setType'] as String?,
      setParams: json['setParams'] as String?,
      completedSetCount: (json['completedSetCount'] as num?)?.toInt() ?? 0,
      totalSetCount: (json['totalSetCount'] as num?)?.toInt() ?? 0,
      bestReps: (json['bestReps'] as num?)?.toDouble(),
      estimatedOneRepMax: (json['estimatedOneRepMax'] as num?)?.toDouble(),
      bestSetVolume: (json['bestSetVolume'] as num?)?.toDouble(),
      bestWeight: (json['bestWeight'] as num?)?.toDouble(),
      bestDurationSeconds: (json['bestDurationSeconds'] as num?)?.toDouble(),
      bestDistanceKm: (json['bestDistanceKm'] as num?)?.toDouble(),
      sets: (json['sets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map((m) => WorkoutInstanceExerciseSet.fromJson(
                m,
                workoutExerciseId: parentId,
              ))
          .toList(),
    );
  }
}
