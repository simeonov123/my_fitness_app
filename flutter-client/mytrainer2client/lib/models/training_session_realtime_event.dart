class TrainingSessionRealtimeEvent {
  const TrainingSessionRealtimeEvent({
    required this.type,
    required this.sessionId,
    this.session,
    this.instanceExercises,
  });

  final String type;
  final int sessionId;
  final Map<String, dynamic>? session;
  final List<Map<String, dynamic>>? instanceExercises;

  factory TrainingSessionRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return TrainingSessionRealtimeEvent(
      type: json['type'] as String? ?? '',
      sessionId: (json['sessionId'] as num).toInt(),
      session: json['session'] as Map<String, dynamic>?,
      instanceExercises: (json['instanceExercises'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
    );
  }
}
