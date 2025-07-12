import 'package:flutter/material.dart';
import '../models/workout_instance_exercise.dart';
import '../services/workout_instance_exercises_api_service.dart';

class WorkoutInstanceExercisesProvider extends ChangeNotifier {
  final _api = WorkoutInstanceExercisesApiService();

  bool _loading = false;
  List<WorkoutInstanceExercise> _items = [];

  bool get loading => _loading;
  List<WorkoutInstanceExercise> get items =>
      List.unmodifiable(_items);

  Future<void> load({
    required String token,
    required int sessionId,
  }) async {
    _loading = true;
    notifyListeners();
    _items = await _api.list(token: token, sessionId: sessionId);
    _loading = false;
    notifyListeners();
  }

  Future<void> replaceAll({
    required String token,
    required int sessionId,
    required List<WorkoutInstanceExercise> newList,
  }) async {
    _loading = true;
    notifyListeners();
    _items = await _api.replaceAll(
      token: token,
      sessionId: sessionId,
      items: newList,
    );
    _loading = false;
    notifyListeners();
  }
}
