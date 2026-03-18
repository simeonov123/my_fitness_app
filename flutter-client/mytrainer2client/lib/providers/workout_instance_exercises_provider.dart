import 'package:flutter/material.dart';
import '../models/workout_instance_exercise.dart';
import '../services/workout_instance_exercises_api_service.dart';

class WorkoutInstanceExercisesProvider extends ChangeNotifier {
  final _api = WorkoutInstanceExercisesApiService();

  bool _loading = false;
  List<WorkoutInstanceExercise> _items = [];

  bool get loading => _loading;
  List<WorkoutInstanceExercise> get items => List.unmodifiable(_items);

  Future<void> load({
    required int sessionId,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _api.list(sessionId: sessionId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> replaceAll({
    required int sessionId,
    required List<WorkoutInstanceExercise> newList,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _api.replaceAll(
        sessionId: sessionId,
        items: newList,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
