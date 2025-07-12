import '../models/workout_instance_exercise.dart';
import 'training_sessions_api_service.dart';

class WorkoutInstanceExercisesApiService {
  final _tsApi = TrainingSessionsApiService();

  Future<List<WorkoutInstanceExercise>> list({
    required String token,
    required int sessionId,
  }) =>
      _tsApi.listInstanceExercises(token: token, sessionId: sessionId);

  Future<List<WorkoutInstanceExercise>> replaceAll({
    required String token,
    required int sessionId,
    required List<WorkoutInstanceExercise> items,
  }) =>
      _tsApi.replaceInstanceExercises(
          token: token, sessionId: sessionId, items: items);
}
