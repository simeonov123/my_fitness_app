class CopyWorkoutRequest {
  final String? sessionName;
  final DateTime startTime;
  final DateTime endTime;

  const CopyWorkoutRequest({
    required this.sessionName,
    required this.startTime,
    required this.endTime,
  });
}
