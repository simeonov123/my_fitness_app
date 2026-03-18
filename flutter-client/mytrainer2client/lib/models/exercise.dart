// lib/models/exercise.dart
import 'muscle_group.dart';

class Exercise {
  final int id;
  final String name;
  final String? description;
  final bool isCustom;
  final String? defaultSetType;
  final String? defaultSetParams;
  final List<MuscleGroup> muscleGroups;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.isCustom = true, // default value
    this.defaultSetType,
    this.defaultSetParams,
    this.muscleGroups = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        description: j['description'] as String?,
        isCustom: j['isCustom'] as bool? ?? true,
        defaultSetType: j['defaultSetType'] as String?,
        defaultSetParams: j['defaultSetParams'] as String?,
        muscleGroups: (j['muscleGroups'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(MuscleGroup.fromJson)
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isCustom': isCustom,
        'defaultSetType': defaultSetType,
        'defaultSetParams': defaultSetParams,
        'muscleGroups': muscleGroups.map((group) => group.toJson()).toList(),
      };
}
