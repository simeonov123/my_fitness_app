// lib/providers/workout_template_exercises_provider.dart

import 'package:flutter/material.dart';
import '../models/workout_template_exercise.dart';
import '../services/workout_template_exercises_api_service.dart';

class WorkoutTemplateExercisesProvider extends ChangeNotifier {
  final _api = WorkoutTemplateExercisesApiService();

  bool _loading = false;
  List<WorkoutTemplateExercise> _items = [];

  bool get loading => _loading;
  List<WorkoutTemplateExercise> get items => List.unmodifiable(_items);

  Future<void> load({
    required String token,
    required int templateId,
  }) async {
    _loading = true;
    notifyListeners();
    _items = await _api.list(templateId: templateId);
    _loading = false;
    notifyListeners();
  }

  Future<void> replaceAll({
    required String token,
    required int templateId,
    required List<WorkoutTemplateExercise> newList,
  }) async {
    _loading = true;
    notifyListeners();
    _items = await _api.replaceAll(
      templateId: templateId,
      items: newList,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> deleteOne({
    required String token,
    required int templateId,
    required int exerciseEntryId,
  }) async {
    _loading = true;
    notifyListeners();
    await _api.deleteOne(
      templateId: templateId,
      exerciseEntryId: exerciseEntryId,
    );
    _items.removeWhere((e) => e.id == exerciseEntryId);
    _loading = false;
    notifyListeners();
  }
}
