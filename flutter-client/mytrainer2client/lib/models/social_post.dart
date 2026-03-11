class SocialLeaderboardEntry {
  final String clientName;
  final double totalWeightLifted;

  const SocialLeaderboardEntry({
    required this.clientName,
    required this.totalWeightLifted,
  });

  factory SocialLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      SocialLeaderboardEntry(
        clientName: json['clientName'] as String,
        totalWeightLifted: (json['totalWeightLifted'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'clientName': clientName,
        'totalWeightLifted': totalWeightLifted,
      };
}

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
  final List<SocialLeaderboardEntry> leaderboard;

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
    this.leaderboard = const [],
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
        leaderboard: (json['leaderboard'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SocialLeaderboardEntry.fromJson)
            .toList(growable: false),
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
        'leaderboard': leaderboard.map((entry) => entry.toJson()).toList(),
      };
}
