class SocialPost {
  final String id;
  final String title;
  final String workoutTitle;
  final String trainerName;
  final String clientSummary;
  final DateTime completedAt;
  final int durationSeconds;
  final double totalWeightLifted;
  final int exerciseCount;

  const SocialPost({
    required this.id,
    required this.title,
    required this.workoutTitle,
    required this.trainerName,
    required this.clientSummary,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalWeightLifted,
    required this.exerciseCount,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        title: json['title'] as String,
        workoutTitle: json['workoutTitle'] as String,
        trainerName: json['trainerName'] as String,
        clientSummary: json['clientSummary'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        totalWeightLifted: (json['totalWeightLifted'] as num).toDouble(),
        exerciseCount: (json['exerciseCount'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'workoutTitle': workoutTitle,
        'trainerName': trainerName,
        'clientSummary': clientSummary,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'totalWeightLifted': totalWeightLifted,
        'exerciseCount': exerciseCount,
      };
}
