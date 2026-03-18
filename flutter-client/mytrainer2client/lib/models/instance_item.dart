import 'workout_template_exercise.dart';

/// UI wrapper that keeps the original instance-exercise id together with
/// an editable [WorkoutTemplateExercise] copy used by the widgets.
class InstanceItem {
  int instanceId; // DB id (0 = brand-new)
  int workoutInstanceId;
  int? clientId;
  String? clientName;
  WorkoutTemplateExercise wte; // editable copy

  InstanceItem(
    this.instanceId,
    this.workoutInstanceId,
    this.clientId,
    this.clientName,
    this.wte,
  );
}
