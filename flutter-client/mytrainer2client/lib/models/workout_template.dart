// lib/models/workout_template.dart
import 'workout_template_exercise.dart';

class WorkoutTemplate {
  final int id;
  final String name;
  final String? description;
  final int? folderId;
  final String? folderName;
  final int? sequenceOrder;
  List<WorkoutTemplateExercise> exercises;  // now mutable, non-final
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    this.folderId,
    this.folderName,
    this.sequenceOrder,
    List<WorkoutTemplateExercise>? exercises,
    this.createdAt,
    this.updatedAt,
  }) : exercises = exercises ?? [];

  factory WorkoutTemplate.fromJson(Map<String, dynamic> j) =>
      WorkoutTemplate(
        id: j['id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        folderId: j['folderId'] as int?,
        folderName: j['folderName'] as String?,
        sequenceOrder: j['sequenceOrder'] as int?,
        exercises: ((j['exercises'] ?? j['workoutTemplateExercises']) as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map(WorkoutTemplateExercise.fromJson)
            .toList(),
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
    'description': description,
    'folderId': folderId,
    'folderName': folderName,
    'sequenceOrder': sequenceOrder,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
