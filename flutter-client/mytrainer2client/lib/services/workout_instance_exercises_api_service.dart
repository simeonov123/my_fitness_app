import '../models/workout_instance_exercise.dart';
import 'training_sessions_api_service.dart';

class WorkoutInstanceExercisesApiService {
  final _tsApi = TrainingSessionsApiService();

  Future<List<WorkoutInstanceExercise>> list({
    required int sessionId,
  }) =>
      _tsApi.listInstanceExercises(sessionId: sessionId);

  Future<List<WorkoutInstanceExercise>> replaceAll({
    required int sessionId,
    required List<WorkoutInstanceExercise> items,
  }) =>
      _tsApi.replaceInstanceExercises(
          sessionId: sessionId, items: items);
}
