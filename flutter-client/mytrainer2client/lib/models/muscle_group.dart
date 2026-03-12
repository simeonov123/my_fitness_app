class MuscleGroup {
  final int id;
  final String name;
  final bool isCustom;

  const MuscleGroup({
    required this.id,
    required this.name,
    this.isCustom = false,
  });

  factory MuscleGroup.fromJson(Map<String, dynamic> j) => MuscleGroup(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        isCustom: j['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCustom': isCustom,
      };
}
