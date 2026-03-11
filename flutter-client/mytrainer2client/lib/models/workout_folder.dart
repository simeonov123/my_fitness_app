class WorkoutFolder {
  final int id;
  final String name;
  final int? sequenceOrder;
  final int workoutCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkoutFolder({
    required this.id,
    required this.name,
    this.sequenceOrder,
    this.workoutCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkoutFolder.fromJson(Map<String, dynamic> j) => WorkoutFolder(
        id: j['id'] as int,
        name: j['name'] as String,
        sequenceOrder: j['sequenceOrder'] as int?,
        workoutCount: (j['workoutCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequenceOrder': sequenceOrder,
      };
}
