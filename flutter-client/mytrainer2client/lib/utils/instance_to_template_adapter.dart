import '../models/workout_instance_exercise.dart';
import '../models/workout_template_exercise.dart';
import '../models/workout_template_exercise_set.dart';

extension InstanceAdapter on WorkoutInstanceExercise {
  /// Lightweight clone so UI-widgets that expect `WorkoutTemplateExercise`
  /// can be reused without big refactors.
  WorkoutTemplateExercise asTemplate() => WorkoutTemplateExercise(
        id: id,
        exercise: exercise,
        sequenceOrder: sequenceOrder,
        setType: setType,
        setParams: setParams,
        notes: notes,
        sets: sets
            .map((s) => WorkoutTemplateExerciseSet(
                  id: s.id,
                  workoutExerciseId: s.workoutExerciseId,
                  setNumber: s.setNumber,
                  values: Map.from(s.values),
                ))
            .toList(),
      );
}

extension InstanceListAdapter on List<WorkoutInstanceExercise> {
  List<WorkoutTemplateExercise> asTemplate() =>
      map((e) => e.asTemplate()).toList();
}
