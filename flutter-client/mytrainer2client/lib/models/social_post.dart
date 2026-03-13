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

class SocialPerformanceHighlight {
  final String label;
  final String value;
  final String detail;

  const SocialPerformanceHighlight({
    required this.label,
    required this.value,
    required this.detail,
  });

  factory SocialPerformanceHighlight.fromJson(Map<String, dynamic> json) =>
      SocialPerformanceHighlight(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'detail': detail,
      };
}

class SocialPost {
  final String id;
  final String ownerRole;
  final int? ownerClientId;
  final String? ownerClientName;
  final String title;
  final String workoutTitle;
  final String trainerName;
  final String clientSummary;
  final DateTime completedAt;
  final int durationSeconds;
  final double totalWeightLifted;
  final double sessionTotalWeightLifted;
  final int exerciseCount;
  final int participantCount;
  final int completedSetCount;
  final int totalSetCount;
  final double bestSetKg;
  final int bestSetReps;
  final int? rank;
  final List<SocialLeaderboardEntry> leaderboard;
  final SocialPerformanceHighlight? bestVolumeHighlight;
  final SocialPerformanceHighlight? heaviestHighlight;
  final SocialPerformanceHighlight? bestRepsHighlight;

  const SocialPost({
    required this.id,
    required this.ownerRole,
    required this.title,
    required this.workoutTitle,
    required this.trainerName,
    required this.clientSummary,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalWeightLifted,
    required this.sessionTotalWeightLifted,
    required this.exerciseCount,
    required this.participantCount,
    required this.completedSetCount,
    required this.totalSetCount,
    required this.bestSetKg,
    required this.bestSetReps,
    this.ownerClientId,
    this.ownerClientName,
    this.rank,
    this.leaderboard = const [],
    this.bestVolumeHighlight,
    this.heaviestHighlight,
    this.bestRepsHighlight,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        ownerRole: (json['ownerRole'] as String? ?? 'TRAINER').toUpperCase(),
        ownerClientId: (json['ownerClientId'] as num?)?.toInt(),
        ownerClientName: json['ownerClientName'] as String?,
        title: json['title'] as String,
        workoutTitle: json['workoutTitle'] as String,
        trainerName: json['trainerName'] as String,
        clientSummary: json['clientSummary'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        totalWeightLifted: (json['totalWeightLifted'] as num).toDouble(),
        sessionTotalWeightLifted:
            (json['sessionTotalWeightLifted'] as num?)?.toDouble() ??
                (json['totalWeightLifted'] as num).toDouble(),
        exerciseCount: (json['exerciseCount'] as num).toInt(),
        participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
        completedSetCount: (json['completedSetCount'] as num?)?.toInt() ?? 0,
        totalSetCount: (json['totalSetCount'] as num?)?.toInt() ?? 0,
        bestSetKg: (json['bestSetKg'] as num?)?.toDouble() ?? 0,
        bestSetReps: (json['bestSetReps'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt(),
        leaderboard: (json['leaderboard'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SocialLeaderboardEntry.fromJson)
            .toList(growable: false),
        bestVolumeHighlight: json['bestVolumeHighlight'] == null
            ? null
            : SocialPerformanceHighlight.fromJson(
                (json['bestVolumeHighlight'] as Map).cast<String, dynamic>(),
              ),
        heaviestHighlight: json['heaviestHighlight'] == null
            ? null
            : SocialPerformanceHighlight.fromJson(
                (json['heaviestHighlight'] as Map).cast<String, dynamic>(),
              ),
        bestRepsHighlight: json['bestRepsHighlight'] == null
            ? null
            : SocialPerformanceHighlight.fromJson(
                (json['bestRepsHighlight'] as Map).cast<String, dynamic>(),
              ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerRole': ownerRole,
        'ownerClientId': ownerClientId,
        'ownerClientName': ownerClientName,
        'title': title,
        'workoutTitle': workoutTitle,
        'trainerName': trainerName,
        'clientSummary': clientSummary,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'totalWeightLifted': totalWeightLifted,
        'sessionTotalWeightLifted': sessionTotalWeightLifted,
        'exerciseCount': exerciseCount,
        'participantCount': participantCount,
        'completedSetCount': completedSetCount,
        'totalSetCount': totalSetCount,
        'bestSetKg': bestSetKg,
        'bestSetReps': bestSetReps,
        'rank': rank,
        'leaderboard': leaderboard.map((entry) => entry.toJson()).toList(),
        'bestVolumeHighlight': bestVolumeHighlight?.toJson(),
        'heaviestHighlight': heaviestHighlight?.toJson(),
        'bestRepsHighlight': bestRepsHighlight?.toJson(),
      };
}
