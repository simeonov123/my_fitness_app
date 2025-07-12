import 'workout_template_exercise.dart';

/// UI wrapper that keeps the original instance-exercise id together with
/// an editable [WorkoutTemplateExercise] copy used by the widgets.
class InstanceItem {
  int instanceId;                  // DB id (0 = brand-new)
  WorkoutTemplateExercise wte;     // editable copy

  InstanceItem(this.instanceId, this.wte);
}
